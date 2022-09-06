pragma solidity 0.8.13;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ERC1155Base.sol";

contract IkonicERC1155Token is ERC1155Base {
    using ECDSA for bytes32;

    string public name;
    string public symbol;

    address private signer;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: IKONIC Token
     * @param _symbol symbol of the token ex: IKONIC
     * @param _baseURI ex: https://ipfs.ikonic.com/
     * @param _signer address of signer account
    */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _signer
    ) ERC1155Base(_baseURI) {
        name = _name;
        symbol = _symbol;
        signer = _signer;
        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
    }

    /**
     * @notice mint ERC1155 token
     * @param _tokenId token ID
     * @param _supply token quantity
     * @param _uri token URI
     * @param royaltyRecipient royalty recipient address
     * @param royaltyValue royalty fee value
     * @param sig signature
     * @param _fees affiliate fee array
     */
    function mint(
        uint256 _tokenId,
        uint256 _supply,
        string memory _uri,
        address royaltyRecipient,
        uint256 royaltyValue,
        bytes memory sig,
        AffiliateFee[] memory _fees
    ) external {
        require(
            keccak256(abi.encodePacked(address(this), _tokenId, msg.sender)).toEthSignedMessageHash().recover(sig) == signer,
            "IkonicERC1155Token.mint: Invalid signature"
        );
        _mint(_tokenId, _supply, _uri, royaltyRecipient, royaltyValue, _fees);
    }

    /**
     * @notice set signer address
     * @param _signer signer address
     */
    function setSignerAddress(address _signer) external onlyOwner {
        require(_signer != address(0x0), "IkonicERC1155Token.setSignerAddress; Invalid address");
        signer = _signer;
    }

    /// @notice returns signer address
    function getSignerAddress() external view returns(address) {
        return signer;
    }

    /** 
     * @notice set base URI
     * @param _tokenURIPrefix base URI
     */
    function setBaseURI(string memory _tokenURIPrefix) external onlyOwner {
        _setTokenURIPrefix(_tokenURIPrefix);
    }
}