// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TwistedApe is ERC721, AccessControlEnumerable, Ownable {
    using SafeERC20 for IERC20;

    enum SaleState {
        OFF,
        PUBLIC
    }

    SaleState public saleState;
    bytes32 public constant DEV = keccak256("DEV");
    address public immutable APE;
    string public baseURI;
    uint256 public counter;
    uint256 public price = 100 ether;
    uint256 public constant supply = 1000;
    uint256 public constant PUBLIC_MAX_PER_TRANSACTION = 1;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        address _APE
    ) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEV, msg.sender);
        baseURI = _tokenURI;
        APE = _APE;
    }

    /// @dev must be in PUBLIC state
    /// @param _numTokens how many tokens caller wants to mint
    function publicMint(uint256 _numTokens) external {
        require(
            saleState == SaleState.PUBLIC,
            "publicMint: must be in PUBLIC state"
        );

        require(
            _numTokens <= PUBLIC_MAX_PER_TRANSACTION,
            "publicMint: Cannot mint more then max per transaction"
        );

        require(
            _numTokens + counter <= supply,
            "publicMint: insufficient supply remaining"
        );

        require(
            _numTokens > 0,
            "publicMint: Must input a number greater than 0"
        );

        IERC20(APE).safeTransferFrom(
            msg.sender,
            address(this),
            _numTokens * price
        );

        for (uint256 i; i < _numTokens; ) {
            _safeMint(msg.sender, counter);
            unchecked {
                ++i;
                ++counter;
            }
        }
    }

    /// @param _saleState is a number 0-1 to set the state of contract
    /// @dev 0-ACTIVE, 1-PUBLIC
    function setSaleState(SaleState _saleState) external onlyRole(DEV) {
        saleState = _saleState;
    }

    /// @param _price is the price of the public sale
    function setPrice(uint256 _price) external onlyRole(DEV) {
        price = _price;
    }

    /// @param _URI is the new IPFS link to update metadata
    function setBaseURI(string memory _URI) external onlyRole(DEV) {
        baseURI = _URI;
    }

    /// @notice withdraw tokens here
    /// @param _destination is the address the owner wants to send funds to
    /// @param _amount how many tokens you would like to withdraw
    function withdraw(
        address _destination,
        uint256 _amount
    ) external onlyRole(DEV) {
        IERC20(APE).safeTransfer(_destination, _amount);
    }

    /// @return returns the URI link
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}