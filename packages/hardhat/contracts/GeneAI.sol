// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Import ERC721Enumerable from OpenZeppelin library to utilize ERC721 standard with enumeration
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// Import Ownable from OpenZeppelin library to manage ownership and access control
import "@openzeppelin/contracts/access/Ownable.sol";

contract GeneAI is ERC721Enumerable, Ownable {

    // Structure to represent an NFT for sale
    struct NftListing {
        address owner;
        uint256 price;
        bool isForSale;
        uint256 royaltyFeePercentage; // New field to store the royalty fee percentage
    }

    // Mapping from token ID to NFT listing
    mapping(uint256 => NftListing) public nftListings;

    // Marketplace fee percentage
    uint256 public marketplaceFeePercentage;

    // Event to track NFT listed for sale
    event NftListed(uint256 indexed tokenId, uint256 price);
    
    // Event to track NFT sale
    event NftSold(uint256 indexed tokenId, uint256 price, address buyer);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        marketplaceFeePercentage = 5; // Default marketplace fee percentage set to 5%
    }

    // Function to list an NFT for sale
    function listNftForSale(uint256 tokenId, uint256 price, uint256 royaltyPercentage) external {
        require(_msgSender() == ownerOf(tokenId), "Not the owner of the NFT");
        nftListings[tokenId] = NftListing(_msgSender(), price, true, royaltyPercentage);
        emit NftListed(tokenId, price);
    }

    // Function to change the price of the listed NFT
    function changeNftPrice(uint256 tokenId, uint256 newPrice) external {
        require(_msgSender() == nftListings[tokenId].owner, "Not the owner of the listing");
        nftListings[tokenId].price = newPrice;
    }

    // Function to unlist an NFT from sale
    function unlistNft(uint256 tokenId) external {
        require(_msgSender() == nftListings[tokenId].owner, "Not the owner of the listing");
        delete nftListings[tokenId];
    }

    // Function to buy an NFT listed for sale
    function buyNft(uint256 tokenId) external payable {
        NftListing storage listing = nftListings[tokenId];
        require(listing.isForSale, "NFT not listed for sale");
        require(msg.value >= listing.price, "Insufficient payment");

        uint256 feeAmount = (listing.price * marketplaceFeePercentage) / 100;
        uint256 royaltyAmount = (listing.price * listing.royaltyFeePercentage) / 100;
        uint256 transferAmount = listing.price - feeAmount - royaltyAmount;

        payable(listing.owner).transfer(transferAmount);
        payable(owner()).transfer(feeAmount);
        payable(ownerOf(tokenId)).transfer(royaltyAmount);

        _transfer(listing.owner, _msgSender(), tokenId);
        listing.isForSale = false;

        emit NftSold(tokenId, listing.price, _msgSender());
    }

    // Function to set the marketplace fee percentage
    function setMarketplaceFeePercentage(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage < 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = newFeePercentage;
    }

    // Function to get the current marketplace fee percentage
    function getMarketplaceFeePercentage() external view returns (uint256) {
        return marketplaceFeePercentage;
    }

    // Function to bundle multiple NFTs together for sale as a package
    function bundleNftsForSale(uint256[] calldata tokenIds, uint256[] calldata prices, uint256 totalPrice) external {
        require(tokenIds.length == prices.length, "Arrays length mismatch");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_msgSender() == ownerOf(tokenIds[i]), "Not the owner of one of the NFTs");
            nftListings[tokenIds[i]] = NftListing(_msgSender(), prices[i], true, 0); // Setting royalty fee to 0 for bundled NFTs
            emit NftListed(tokenIds[i], prices[i]);
        }
    }
}