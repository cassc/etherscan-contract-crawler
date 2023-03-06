// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {OperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/OperatorFiltererUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @author AddressZero.org Team
/// @title Upgradable NFT contract for MagicBatch passes
contract MagicBatch is
    Initializable,
    ERC721Upgradeable,
    ERC2981Upgradeable,
    OperatorFiltererUpgradeable,
    Ownable2StepUpgradeable
{
    // contract storage - core
    string public baseURI;
    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public constant maxTotalSupply = 420;

    mapping(address => uint256) public specificMintPrice;
    mapping(address => uint256[]) public minted;

    // contract storage - whitelisting
    mapping(address => bool) public whitelist;

    // events
    event AddWhitelist(address user);
    event Claimed(address user);
    event ChangeMintPrice(uint256 price);

    // errors
    error Unauthorized(); // if the call is not from the authorised address
    error Underpriced(); // if the value attached is less than the minimum required value
    error InvalidParams(); // if the function params are invalid
    error MaxTotalSupplyReached(); // if total mint of 450

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the pass contract
    /// @param _subscriptionOrRegistrantToCopy Subsctiption or registrant to copy for the blacklist registry
    /// @param _mintPrice The initial mint price
    /// @param _baseURI The initial baseURI
    function initialize(
        address _subscriptionOrRegistrantToCopy,
        uint256 _mintPrice,
        string memory _baseURI
    ) external initializer {
        __ERC721_init("MagicBatch", "MB");
        mintPrice = _mintPrice;
        baseURI = _baseURI;
        __OperatorFilterer_init(_subscriptionOrRegistrantToCopy, false);
        __Ownable2Step_init();
    }

    // Public Functions
    /// @notice Mint for whitelisted individuals
    /// @dev If the specific mint price is setup, use it otherwise use general minting price
    function mint() external payable {
        if (!whitelist[msg.sender]) {
            revert Unauthorized();
        }

        if (specificMintPrice[msg.sender] > 0) {
            if (specificMintPrice[msg.sender] != msg.value)
                revert Underpriced();
        } else {
            if (msg.value != mintPrice) {
                revert Underpriced();
            }
        }

        totalSupply += 1;

        if (totalSupply > maxTotalSupply) {
            revert MaxTotalSupplyReached();
        }

        whitelist[msg.sender] = false;

        _mint(msg.sender, totalSupply);

        minted[msg.sender].push(totalSupply);
    }

    /// @notice Get TokenURI from token ID
    /// @dev returns tokenURI if set specifically, otherwise return baseURI
    /// @param tokenId ID of the token
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
                : "";
    }

    /// @notice Removes the provided tokenId from minted Array
    /// @param user Address of the user
    /// @param tokenId TokenID to be removed from the minted array
    function _removeFromMinted(address user, uint256 tokenId) internal {
        uint256[] storage _array = minted[user];

        for (uint256 i; i < _array.length; i++) {
            if (_array[i] == tokenId) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }

    /// @notice Overrides the original ERC721's function with extra modifier for blacklisting
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /// @notice Overrides the original ERC721's function with extra modifier for blacklisting
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @notice Overrides the original ERC721's function with extra modifier for blacklisting
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @notice Overrides the original ERC721's function with extra modifier for blacklisting
    function approve(address to, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(to)
    {
        super.approve(to, tokenId);
    }

    /// @notice Overrides the original ERC721's function with extra modifier for blacklisting
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    // Owner Functions

    /// @notice Set specific price for a user
    /// @param users Array of the users to add for setting up the specific price
    /// @param prices Array of the prices to be set for the users
    function setSpecificPrice(address[] memory users, uint256[] memory prices)
        external
        onlyOwner
    {
        if (users.length != prices.length) {
            revert InvalidParams();
        }
        for (uint256 i = 0; i < users.length; i++) {
            specificMintPrice[users[i]] = prices[i];
        }
    }

    /// @notice Function to withdraw all Ether from this contract.
    /// @param to Address to which the Ether needs to be withdrawn
    function withdraw(address payable to) public onlyOwner {
        // get the amount of Ether stored in this contract
        uint256 amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    /// @notice Change the default mint price
    /// @param price The new price
    function changeMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
        emit ChangeMintPrice(price);
    }

    /// @notice Adds the array of the users to the whitelist
    /// @param addresses Array of the addresses to be added to the whitelist
    function addWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
            emit AddWhitelist(addresses[i]);
        }
    }

    /// @notice Burn tokenId
    /// @param tokenId ID of the token to be burn
    function burn(uint256 tokenId) external onlyOwner {
        address user = super.ownerOf(tokenId);
        _burn(tokenId);
        _removeFromMinted(user, tokenId);
    }

    /// @notice Mint the token by Governance if required
    /// @dev Should be used to mint the token after burning by governance in case required
    /// @param user Address of the user
    /// @param tokenId TokenID to mint
    function mintByGovernance(address[] memory user, uint256[] memory tokenId)
        external
        onlyOwner
    {
        if (user.length != tokenId.length) {
            revert InvalidParams();
        }

        for (uint256 i = 0; i < user.length; i++) {
            require((0 < tokenId[i]) && (tokenId[i] <= totalSupply), "Invalid");
            _mint(user[i], tokenId[i]);
            minted[user[i]].push(tokenId[i]);
        }
    }

    /// @notice Function to pre-mint the tokens by the governance.
    /// @param user Address of the user
    function preMintByGovernance(address[] memory user) external onlyOwner {
        for (uint256 i = 0; i < user.length; i++) {
            totalSupply += 1;

            if (totalSupply > maxTotalSupply) {
                revert MaxTotalSupplyReached();
            }

            _mint(user[i], totalSupply);

            minted[user[i]].push(totalSupply);
        }
    }

    /// @notice Change the base URI
    /// @param newBaseURI New base uri
    function changeBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @inheritdoc ERC721Upgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Sets default royalty
    /// @param receiver Address of the receiver
    /// @param feeNumerator Fee numerator, 10000 is 100%
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Set Royalty for specific token
    /// @param tokenId Id of the token
    /// @param receiver The receiver of the Royalty
    /// @param feeNumerator The fee numerator, 10000 is 100%
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @notice Deletes the default setup Royalty
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /// @notice Resets the Royalty for specific tokenId
    /// @param tokenId The NFT tokenId
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }
}