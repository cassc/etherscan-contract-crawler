// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./AbstractERC1155Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ApeMadness is AbstractERC1155Factory {
    using ECDSA for bytes32;

    mapping(address => bool) public minted;

    address signer;

    uint128 windowOpens;
    uint128 windowCloses;

    error nonExistentToken();
    error signatureInvalid();
    error amountInvalid();
    error windowClosed();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri, 
        uint128 _windowOpens,
        uint128 _windowCloses,   
        address _signer
    ) ERC1155(_baseUri) {
        name_ = _name;
        symbol_ = _symbol;

        windowOpens = _windowOpens;
        windowCloses = _windowCloses;

        signer = _signer;

        _setURI(_baseUri);
    } 

    function editWindows(
        uint128 _windowOpens, 
        uint128 _windowCloses
    ) external onlyOwner {
        require(_windowOpens < _windowCloses, "open window must be before close window");

        windowOpens = _windowOpens;
        windowCloses = _windowCloses;
    }  

    /**
     * @notice allowlist gated mint
     *
     * @param _signature signature issued by PV
     */
    function mint(
        bytes calldata _signature
    ) external {
        if(block.timestamp < windowOpens || block.timestamp > windowCloses) {
            revert windowClosed();
        }

        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender)
        );
        if (hash.toEthSignedMessageHash().recover(_signature) != signer) {
            revert signatureInvalid();
        }

        if(minted[msg.sender]) {
            revert amountInvalid();
        }   

        minted[msg.sender] = true;

        _mint(msg.sender, 0, 1, "");
    }  


    /**
     * @notice Mints the given amount to receiver address
     *
     * @param _receiver the receiving wallet
     * @param _tokenId the token id to mint
     * @param _amount the amount of tokens to mint
     */
    function ownerMint(
        address _receiver,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        _mint(_receiver, _tokenId, _amount, "");
    }

    /**
     * @notice Edit metadata base URI
     *
     * @param _baseURI the new base URI
     *
     */
    function setBaseURI(
        string memory _baseURI
    ) external onlyOwner {
        _setURI(_baseURI);
    }

    /**
     * @notice Change the wallet address required to sign tickets
     *
     * @param _signer the new signing address
     *
     */
    function setSigner(
        address _signer
    ) external onlyOwner {
        signer = _signer;
    }

    /**
     * @notice returns the metadata uri for a given id
     *
     * @param _id the card id to return metadata for
     */
    function uri(
        uint256 _id
    ) public view override returns (string memory) {
        if (!exists(_id)) revert nonExistentToken();

         return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }
}