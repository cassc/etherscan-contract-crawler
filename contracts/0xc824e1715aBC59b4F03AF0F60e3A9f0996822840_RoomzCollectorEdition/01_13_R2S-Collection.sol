// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RoomzCollectorEdition is ERC1155, Ownable {
    using ECDSA for bytes32;

    struct seriesData {
        bool status;
        uint256 price;
        uint256 limit;
    } 

    string public name = "Roomz 2 Show: Collectors Edition";
    string public symbol = "RTSC";

    mapping(uint256 => string) public tokenURI;
    mapping(uint256 => seriesData) public tokenData;
    mapping(uint256 => mapping(address => uint256)) public mintTracking;
    mapping(address => bool) public managers;

    address private constant DEVELOPER_ONE = 0x3B36Cb2c6826349eEC1F717417f47C06cB70b7Ea;
    address private constant DEVELOPER_TWO = 0x1B996396448767b9e9C96102ccB34816532be974;

    address private signer = 0xA4753b764885142D21856F8B3b30326EB83a599E;

    modifier onlyManagers() {
        require(managers[msg.sender], "Manager Credentials Required");
        _;
    }
    
    constructor() ERC1155("") {
        managers[msg.sender] = true;
    }

    ///@notice Primary mint function
    ///@dev Mint params are determined by tokenData mapping.
    function mint(uint256 id, uint256 amount, bytes memory signature)
        external
        payable
    {
        seriesData memory idData = tokenData[id];
        require(idData.status, "Sale Not Open");
        require(_isValidSignature(signature, id), "Signature Invalid");
        require(msg.value * amount >= idData.price * amount, "Invalid value");
        require(mintTracking[id][msg.sender] + amount <= idData.limit, "Allowance Exceeded");
        mintTracking[id][msg.sender] += amount;
        _mint(msg.sender, id, amount, "");
    }


    ///@notice Manager restricted function that allows for free batch minting
    ///@param to Address to mint to
    ///@param ids Array containing all ids to mint
    ///@param amounts Array containing amounts of each id to mint
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        external 
        onlyManagers
    {
        _mintBatch(to, ids, amounts, "");
    }

    ///@notice Internal helper to verify signature validity
    function _isValidSignature(
        bytes memory signature,
        uint256 id
    ) internal view returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(msg.sender, id));
        return signer == data.toEthSignedMessageHash().recover(signature);
    }

    ///@notice Sets tokenURI for individual token
    ///@dev No base URI; each token set individually
    function setURI(string memory _uri, uint256 tokenId) external onlyManagers {
        tokenURI[tokenId] = _uri;
    }

    ///@notice Function to adjust data by TokenID
    ///@param id TokenID
    ///@param status Sale status: true - open, false - closed
    ///@param price Price per token in wei
    ///@param limit Mint allowance per wallet.
    function adjustData(uint256 id, bool status, uint256 price, uint256 limit) external onlyManagers {
        tokenData[id].status = status;
        tokenData[id].price = price;
        tokenData[id].limit = limit;
    }

    ///@notice Function to adjust sale status of any tokenID
    function toggleSale(uint256 id) external onlyManagers {
        tokenData[id].status = !tokenData[id].status;
    }

    ///@notice Function to adjust manager status.
    function manageManagers(address _address, bool status) external onlyOwner {
        managers[_address] = status;
    }

    ///@notice Function to withdraw funds to project and developers.
    ///@dev Accesible to contract owner.
    function withdraw() external onlyOwner {
        uint256 devFee = (address(this).balance / 10);
        (bool successOne, ) = payable(DEVELOPER_ONE).call{value: devFee}("");
        require(successOne, "Transfer failed.");
        (bool successThree, ) = payable(DEVELOPER_TWO).call{value: devFee}("");
        require(successThree, "Transfer failed.");
        (bool successTwo, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(successTwo, "Transfer failed.");
    }

    ///@notice Function to updated signer address.
    ///@dev Accesible to contract managers.
    function setSigner(address _signer) external onlyManagers {
        signer = _signer;
    }

    ///@notice overriding 1155 uri
    function uri(uint256 id) public view virtual override returns (string memory) {
        return tokenURI[id];
    }

}