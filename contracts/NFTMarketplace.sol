//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    // _tokenIds variable has most recent minted tokenId
    Counters.Counter private _tokenIds;
    // Keeps trac of the number of items sold on the marketplace
    Counters.Counter private _itemSold;
    // owner is th contract address that created the smartcontract
    address payable  owner;
    // The fee charged by the marketplace to be allower list an NFT
    uint256 listPrice = 0.01 ether;

    // The structured to store into about a listed token
    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    // the event emitted when a token is successfully selled
    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address ssller,
        uint256 price,
        bool currentlyListed
    );

    // The mappin maps tokenId to tokeninfo and is helpful when retrieving defauls about a tokenId
    mapping(uint256 => ListedToken) private idToListedToken;

    constructor() ERC721("NFTMarketPlace", "NFTM") {
        owner = payable(msg.sender);
    }

    // The first time a token is creaed it is listed here.
    function createToken(string memory tokenURI, uint256 price) public payable returns(uint) {
        // Increment tge tokenId counter, which is keeping track of the number of minted NFTs
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Mint the NFT with tokenId new TokenId to the address who called createToken
        _safeMint(msg.sender, newTokenId);

        // Map the tokenId to the tokenURI (which is an IPFS URL with the NFT metadata)
        _setTokenURI(newTokenId, tokenURI);

        // Helper function ot update Global valiables and emit an event
        createListedToken(newTokenId, price);

        return newTokenId;
    }

    function createListedToken(uint256 tokenId, uint256 price) private {
        // Make sure the sender sent enough ETH to pay for listing
        require(msg.value == listPrice, "Hepefully sending the correct price");

        // Just sanity check
        require(price > 0 , "Make sure the price isn't nagative");

        idToListedToken[tokenId] = ListedToken({
            tokenId: tokenId,
            owner: payable(address(this)),
            seller: payable(msg.sender),
            price: price,
            currentlyListed: true
        });

        _transfer(msg.sender, address(this), tokenId);

        // Emit the event for successful transfer. The frontedn parses this message and updates the end user
        emit TokenListedSuccess(tokenId, address(this), msg.sender, price, true);
    }

    function getAllNFTs() public view returns(ListedToken[] memory) {
        uint nftCount = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint256 currentIndex = 0;

        // at the moment currentlyListed is true for all, if it becomes false in the future we wll filter out currentlyListed == false over here
        for (uint i = 0; i < nftCount; i++) {
            uint currentId = i + 1;
            ListedToken memory currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }

        return tokens;
    }


    // Returns all NFTs tha the current user i owner or seller in
    function getMyNFTs() public view returns(ListedToken[] memory) {
        uint tokenItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        // Important to get a count of all nft that belong to the user before we can make an array for them
        for (uint i = 0; i < tokenItemCount; i++) {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender) {
                itemCount += 1;
            }
        }
        // Once you have the count of relevant NFTs, create an arrat then store all the NFTs in it
        ListedToken[] memory items = new ListedToken[](itemCount);
        for (uint i = 0; i < itemCount; i++) {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender){
                uint currentId = i+1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return items;
    }



    function executeSale(uint256 tokenId) public payable {
        uint price = idToListedToken[tokenId].price;
        address seller = idToListedToken[tokenId].seller;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase.");

        // update the details of the token
        idToListedToken[tokenId].currentlyListed = true;
        idToListedToken[tokenId].owner = payable(msg.sender);
        _itemSold.increment();

        // Actually transfer the token to the new owner
        _transfer(address(this), msg.sender, tokenId);
        // approve the marketplace to sell NFTs on your behalf
        approve(address(this), tokenId);

        // Tnrasfer the listing fee to the marketplace creator
        payable(owner).transfer(listPrice);
        // Transfer the proceeds from the sale to the seller of the NFT
        payable(seller).transfer(msg.value);

    }



    function updateListedPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only Owner can update listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns(uint256) {
        return listPrice;
    }

    function getLatestIdListedToken() public view returns(ListedToken memory) {
        uint tokenId = _tokenIds.current();
        ListedToken memory item  = idToListedToken[tokenId];
        return item;
    }

    function getListedTokenForId(uint _tokenId) public view returns(ListedToken memory) {
        return idToListedToken[_tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

}
