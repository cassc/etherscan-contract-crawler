// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**----------------------------------------------------------------
   __  ___     ___            __           _  __     __  _         
  /  |/  /_ __/ _ |_  _____ _/ /____ _____/ |/ /__ _/ /_(_)__  ___ 
 / /|_/ / // / __ | |/ / _ `/ __/ _ `/ __/    / _ `/ __/ / _ \/ _ \
/_/  /_/\_, /_/ |_|___/\_,_/\__/\_,_/_/ /_/|_/\_,_/\__/_/\___/_//_/
       /___/                                                       
 ----------------------------------------------------------------*/

/// @author Gen3 Studios
contract MyAvatarNationHonoraryMembers is ERC721A, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    string public baseURI;
    bool private _revealed;

    // General Mint Settings
    uint256 public MAX_SUPPLY = 9;

    // Events
    event PrivateMint(address indexed to, uint256 amount);
    event PublicMint(address indexed to, uint256 amount);
    event DevMint(uint256 count);
    event WithdrawETH(uint256 amountWithdrawn);
    event Revealed(uint256 timestamp);
    event PrivateSaleOpened(bool status, uint256 timestamp);
    event PublicSaleOpened(bool status, uint256 timestamp);

    // Modifiers
    /**
     * @dev Prevent Smart Contracts from calling the functions with this modifier
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "MAN: must use EOA");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address _newOwner,
        string memory _baseURI
    ) ERC721A(name_, symbol_) {
        setBaseURI(_baseURI);
        transferOwnership(_newOwner);
    }

    // -------------------- MINT FUNCTIONS --------------------------

    /**
     * @notice Dev Mint
     * @param _mintAmount Amount that is minted
     */
    function devMint(uint256 _mintAmount) external onlyOwner {
        // Check if mints does not exceed MAX_SUPPLY
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "MyAvatarNationSG: Max Supply Reached!"
        );
        _safeMint(owner(), _mintAmount);
    }

    /**
     * @notice Set Max Supply
     * @param _newMaxSupply Amount that is minted
     */
    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        MAX_SUPPLY = _newMaxSupply;
    }

    // ---------------------- VIEW FUNCTIONS ------------------------
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @dev gets baseURI from contract state variable
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Set Revealed Metadata URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Withdraw Function which splits the ETH to `fundRecipients`
     * @dev requires currentBalance of contract to have some amount
     * @dev withdraws with the fixed define distribution
     */
    function withdrawFund() public onlyOwner {
        uint256 currentBal = address(this).balance;
        _withdraw(owner(), currentBal);
    }

    /**
     * @dev private function utilized by withdrawFund
     * @param _addr Address of receiver
     * @param _amt Amount to withdraw
     */
    function _withdraw(address _addr, uint256 _amt) private {
        (bool success, ) = _addr.call{value: _amt}("");
        require(success, "Transfer failed");
    }

    /**
     * @dev Returns the starting token ID.
     * MAN - Override to start from tokenID 1
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}