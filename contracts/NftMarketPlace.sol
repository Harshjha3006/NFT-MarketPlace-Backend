// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NftMarketPlace__NotApproved();
error NftMarketPlace__NotOwner();
error NftMarketPlace__AlreadyListed();
error NftMarketPlace__NotListed();
error NftMarketPlace__NotEnoughEth();
error NftMarketPlace__TransactionFailed();
error NftMarketPlace__PriceMustBeAboveZero();
error NftMarketPlace__NoProceeds();

contract NftMarketPlace is ReentrancyGuard {
  struct Listing {
    uint256 price;
    address seller;
  }
  mapping(address => mapping(uint256 => Listing)) s_listings;
  mapping(address => uint256) s_proceeds;

  event ItemListed(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address indexed seller
  );
  event ItemBought(
    address indexed nftAddress,
    uint256 indexed tokenId,
    address indexed buyer
  );
  event ItemCancelled(
    address indexed nftAddress,
    uint256 indexed tokenId,
    address seller
  );

  modifier isOwner(
    address nftAddress,
    uint256 tokenId,
    address sender
  ) {
    if (IERC721(nftAddress).ownerOf(tokenId) != sender) {
      revert NftMarketPlace__NotOwner();
    }
    _;
  }
  modifier isNotListed(address nftAddress, uint256 tokenId) {
    if (s_listings[nftAddress][tokenId].price > 0) {
      revert NftMarketPlace__AlreadyListed();
    }
    _;
  }
  modifier isListed(address nftAddress, uint256 tokenId) {
    if (s_listings[nftAddress][tokenId].price <= 0) {
      revert NftMarketPlace__NotListed();
    }
    _;
  }

  function listItem(
    address nftAddress,
    uint256 tokenId,
    uint256 price
  )
    external
    isOwner(nftAddress, tokenId, msg.sender)
    isNotListed(nftAddress, tokenId)
  {
    if (price <= 0) {
      revert NftMarketPlace__PriceMustBeAboveZero();
    }
    IERC721 nft = IERC721(nftAddress);
    if (nft.getApproved(tokenId) != address(this)) {
      revert NftMarketPlace__NotApproved();
    }
    s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
    emit ItemListed(nftAddress, tokenId, price, msg.sender);
  }

  function buyItem(
    address nftAddress,
    uint256 tokenId
  ) external payable isListed(nftAddress, tokenId) nonReentrant {
    Listing memory listings = s_listings[nftAddress][tokenId];
    if (msg.value < listings.price) {
      revert NftMarketPlace__NotEnoughEth();
    }
    delete (s_listings[nftAddress][tokenId]);
    s_proceeds[listings.seller] += listings.price;
    IERC721(nftAddress).safeTransferFrom(listings.seller, msg.sender, tokenId);
    emit ItemBought(nftAddress, tokenId, msg.sender);
  }

  function cancelListing(
    address nftAddress,
    uint256 tokenId
  )
    external
    isOwner(nftAddress, tokenId, msg.sender)
    isListed(nftAddress, tokenId)
  {
    delete (s_listings[nftAddress][tokenId]);
    emit ItemCancelled(nftAddress, tokenId, msg.sender);
  }

  function updateListing(
    address nftAddress,
    uint256 tokenId,
    uint256 newPrice
  )
    external
    isOwner(nftAddress, tokenId, msg.sender)
    isListed(nftAddress, tokenId)
    nonReentrant
  {
    if (newPrice <= 0) {
      revert NftMarketPlace__PriceMustBeAboveZero();
    }
    s_listings[nftAddress][tokenId].price = newPrice;
    emit ItemListed(
      nftAddress,
      tokenId,
      newPrice,
      s_listings[nftAddress][tokenId].seller
    );
  }

  function withdrawProceeds() external {
    uint256 proceeds = s_proceeds[msg.sender];
    if (proceeds <= 0) {
      revert NftMarketPlace__NoProceeds();
    }
    s_proceeds[msg.sender] = 0;
    (bool success, ) = payable(msg.sender).call{ value: proceeds }("");
    if (!success) {
      revert NftMarketPlace__TransactionFailed();
    }
  }

  function getListing(
    address nftAddress,
    uint256 tokenId
  ) public view returns (Listing memory) {
    return s_listings[nftAddress][tokenId];
  }

  function getProceeds(address owner) public view returns (uint256) {
    return s_proceeds[owner];
  }
}
