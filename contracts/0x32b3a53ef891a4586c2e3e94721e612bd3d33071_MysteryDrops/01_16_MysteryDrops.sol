// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract MysteryDrops is ERC1155, Ownable, ERC1155Supply, IERC2981 {
    using ECDSA for bytes32;

    uint256 public mintingFee = 0.35 ether;
    address public signer;
    address private _market;
    bool public paused;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }
    //Info for royalty
    RoyaltyInfo private _royaltyInfos;

    mapping(uint256 => uint256) public maxSupply;
    mapping(address => uint) public nonces;
    mapping(uint256 => string) private _tokenUri;

    constructor(
        address _signer,
        address _marketplace,
        string memory _hiddenUri,
        uint96 _royaltyFraction
    ) ERC1155("") {
        signer = _signer;
        _market = _marketplace;
        _tokenUri[1] = _hiddenUri;
        maxSupply[1] = 50;
        _royaltyInfos = RoyaltyInfo(_msgSender(), _royaltyFraction);
    }

    /**
     * @notice Sets the minting fee required to mint tokens
     * @param newFee uint
     */
    function setMintingFee(uint256 newFee) external onlyOwner {
        mintingFee = newFee;
    }

    /**
     * @notice Sets the token uri
     * @param tokenId uint
     * @param tokenUri string
     */
    function setTokenUri(
        uint256 tokenId,
        string calldata tokenUri
    ) external onlyOwner {
        _tokenUri[tokenId] = tokenUri;
        emit URI(_tokenUri[tokenId], tokenId);
    }

    /**
     * @notice Sets the max supply of specific token id
     * @param tokenId uint
     * @param supply uint
     */
    function setMaxSupply(uint256 tokenId, uint256 supply) external onlyOwner {
        require(tokenId > 0 && supply > 0, "Invalid parameters");
        maxSupply[tokenId] = supply;
    }

    /**
     * @notice Sets the signer wallet address
     * @param _signer address
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * @notice Sets the pause status
     * @param _status bool
     */
    function setPause(bool _status) external onlyOwner {
        paused = _status;
    }

    /**
     * @notice Update royalty information
     * @param _receiver address
     * @param _royaltyFraction uint96
     */
    function setRoyaltyInfo(
        address _receiver,
        uint96 _royaltyFraction
    ) external onlyOwner {
        require(_receiver != address(0) && _royaltyFraction > 0, "Invalid parameters");
        _royaltyInfos = RoyaltyInfo(_receiver, _royaltyFraction);
    }

    /**
     * @notice Mints a specified amount of tokens to the sender address
     * @param tokenId uint
     * @param amount uint
     * @param sig bytes
     */
    function mint(
        uint256 tokenId,
        uint256 amount,
        bytes calldata sig
    ) external payable {
        require(!paused, "Contract paused");
        require(tokenId > 0 && amount > 0, "Invalid parameters");
        require(maxSupply[tokenId] > 0, "Supply not set");
        require(
            totalSupply(tokenId) + amount <= maxSupply[tokenId],
            "Max supply reached"
        );
        require(msg.value == mintingFee * amount, "Incorrect minting fee");
        address sigRecover = keccak256(
            abi.encodePacked(
                _msgSender(),
                tokenId,
                amount,
                nonces[_msgSender()]
            )
        ).toEthSignedMessageHash().recover(sig);

        require(sigRecover == signer, "Invalid Signer");
        nonces[_msgSender()]++;
        _mint(_msgSender(), tokenId, amount, "");
    }

    /**
     * @notice Withdraws the contract's balance to the owner's address
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * Override setApprovalForAll to auto restrict marketplace contract
     * @param operator address
     * @param approved bool
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        if (operator == _market) {
            revert("Approval not allowed");
        }
        super._setApprovalForAll(_msgSender(), operator, approved);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @notice Returns the URI for a given token Id
     * @param tokenId uint
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(exists(tokenId), "Non-existent token Id");
        return _tokenUri[tokenId];
    }

    /**
     * @dev Returns the royalty information for `_tokenId` and `_salePrice`
     * @param _tokenId uint
     * @param _salePrice uint
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256) {
        _tokenId;
        uint256 royaltyAmount = (_salePrice * _royaltyInfos.royaltyFraction) /
            10000; // expressed in basis points
        return (_royaltyInfos.receiver, royaltyAmount);
    }
}