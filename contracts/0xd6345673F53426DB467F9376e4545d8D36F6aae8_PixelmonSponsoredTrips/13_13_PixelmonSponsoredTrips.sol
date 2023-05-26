// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

///@notice Thrown when address is not registered as minter
error NotMinter();

///@notice Thrown when address input is 0x0
error InvalidAddress();

///@notice Thrown when isMintingAllowed value is false
error MintingIsDisabled();

///@notice Thrown when isBurningAllowed value is false
error BurningIsDisabled();

using Strings for uint8;

contract PixelmonSponsoredTrips is ERC1155, Ownable, ReentrancyGuard {
    uint8 constant TOKEN_ID = 1;

    ///@notice Token total supply in the contract
    ///@dev The value can't be less than equal to mintedTokenAmount
    uint256 public tokenTotalSupply;

    ///@notice Total token that's been minted by user
    ///@dev Increased every time mint method is called
    uint256 public mintedTokenAmount = 0;

    ///@notice Whether mint functionality is activated or not
    bool public isMintingAllowed = true;

    ///@notice Whether burn functionality is activated or not
    bool public isBurningAllowed;

    ///@notice List of address that is allowed to mint. 'false' means not allowed/registered, 'true' means allowed
    mapping(address => bool) public minterList;

    ///@notice Metadata base URI
    string public baseURI = "";

    constructor(uint256 _tokenTotalSupply, string memory metadataURI) ERC1155(baseURI) {
      baseURI = metadataURI;
      tokenTotalSupply = _tokenTotalSupply;
    }

    event Burn(address indexed from, uint8 indexed token, uint256 amount);
    event Mint(address indexed to, uint8 indexed token, uint256 amount);

    ///@dev Check whether address is allowed to mint, throw NotMinter if not allowed
    modifier onlyMinter() {
        if (!minterList[msg.sender]) {
            revert NotMinter();
        }
        _;
    }

    ///@dev Check whether address is 0x0, throw InvalidAddress if true
    ///@param _address Input address
    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert InvalidAddress();
        }
        _;
    }

    ///@notice Set available token supply. It's not allowed to set the supply less than mintedTokenAmount
    ///@dev Only owner can execute this function
    ///@param _newSupply amount of new supply
    function setTokenSupply(uint256 _newSupply) external onlyOwner {
        require(
            _newSupply >= mintedTokenAmount,
            "Supply can't be less than amount of minted token"
        );
        tokenTotalSupply = _newSupply;
    }

    ///@notice Set metadata base URI, it will override baseURI value.
    ///@dev Only owner can execute this function
    ///@param _newURI metadata URL
    function setURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    ///@notice Activate/deactivate minting functionality, set 'true' to activate and 'false' to deactivate
    ///@param _status Whether user able to mint
    function setMintingStatus(bool _status) external onlyOwner {
        isMintingAllowed = _status;
    }

    ///@notice Activate/deactivate burning functionality, set 'true' to activate and 'false' to deactivate
    ///@param _status Whether user able to burn
    function setBurningStatus(bool _status) external onlyOwner {
        isBurningAllowed = _status;
    }

    ///@notice Set address permission to call mint method, set 'true' to allow and 'false' to disallow
    ///@dev Only owner can execute this function
    ///@param _address Minter address
    ///@param _mintingPermission Whether address is allowed to mint
    function setMinterAddress(address _address, bool _mintingPermission)
        external
        onlyOwner
        validAddress(_address)
    {
        minterList[_address] = _mintingPermission;
    }

    ///@notice Burn the caller's token
    ///@param _amount Amount of token to burn
    function burn(uint256 _amount) external virtual {
        if (!isBurningAllowed) {
            revert BurningIsDisabled();
        }

        _burn(msg.sender, TOKEN_ID, _amount);
        emit Burn(msg.sender, TOKEN_ID, _amount);
    }

    ///@notice Mint token to specified address
    ///@param _to Address who receives the token
    ///@param _to Amount of token to mint
    function mint(address _to, uint256 _amount)
        external
        nonReentrant
        onlyMinter
        validAddress(_to)
    {
        if (!isMintingAllowed) {
            revert MintingIsDisabled();
        }

        require(_amount > 0, "Can't mint 0 token");
        require(
            mintedTokenAmount + _amount <= tokenTotalSupply,
            "Can't mint more than total supply"
        );

        unchecked {
            mintedTokenAmount += _amount;
        }

        _mint(_to, TOKEN_ID, _amount, "");
        emit Mint(_to, TOKEN_ID, _amount);
    }

    ///@notice Token metadata URL, it won't return the expected token ID but token ID in smart contract
    ///@dev This function is to override the OpenZeppelin ERC1155 'uri' method
    function uri(uint256) public view virtual override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, TOKEN_ID.toString()))
                : "";
    }
}