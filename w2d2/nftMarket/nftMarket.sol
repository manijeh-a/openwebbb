// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract nftMarket is IERC721Receiver {
    address public owner;
    IERC721 public nft;
    IERC20  public token;

    struct NFTList{
        address seller;
        uint256 price;
    }

    // NFTList[] userList;
    mapping(uint256 => NFTList) public nftListings;

    event ListNFT(address indexed seller, uint256 indexed tokenId, uint256 price);
    event DealNFT(address indexed buyer, uint256 indexed tokenId, uint256 price);

    constructor(address _token, address _nft) {
        owner = msg.sender;
        nft = IERC721(_nft);
        token = IERC20(_token);
    }

    // nft list for sale
    // transfer the nft to nftmarket
    function list(uint256 tokenId, uint256 price) public returns(bool) {
        require(nft.ownerOf[tokenId] == msg.sender, "not the owner of nft");
        require(price > 0, "price must be greater than 0");

        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        nftListings[tokenId] = NFTList({seller: msg.sender, price: price});
        emit ListNFT(msg.sender, tokenId, price);
    }

    function buyNFT(uint256 tokenId) public returns(bool) {
        nftListings memory nl = nftListings[tokenId];

        token.transferFrom(msg.sender, address(this), nl.price);
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        token.transfer(nl.seller, nl.price);
        // token.transferWithCallback(nl.seller, nl.price, data);

        delete nftListings[tokenId];

        emit DealNFT(msg.sender, tokenId, nl.price);
    }

    // function buyNFTCallback(uint256 tokenId) public returns(bool) {
    //     nftListings memory nl = nftListings[tokenId];

    //     token.transferFrom(msg.sender, address(this), nl.price);
    //     nft.safeTransferFrom(address(this), msg.sender, tokenId);

    //     bytes memory data = abi.encodePacked(tokenId);
    //     token.transferWithCallback(nl.seller, nl.price, data);

    //     delete nftListings[tokenId];

    //     emit DealNFT(msg.sender, tokenId, nl.price);
    // }

    function tokensReceived(
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) external {
        // tokenId must be passed in data
        require(data.length == 32, "Invalid data"); 
        uint256 tokenId = abi.decode(data, (uint256));

        nftListings memory nl = nftListings[tokenId];
        require(nl.price > 0, "nft not for sale");
        require(amount >= nl.price, "Insufficient price");

        nft.safeTransferFrom(address(this), from, tokenId);
        token.transfer(nl.seller, amount);

        delete nftListings[tokenId];

        emit DealNFT(msg.sender, tokenId, nl.price);
    }

    // Required for receiving NFTs
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

}