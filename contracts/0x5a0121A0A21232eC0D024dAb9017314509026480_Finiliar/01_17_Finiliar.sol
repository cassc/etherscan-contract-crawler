// SPDX-License-Identifier: GPL-3.0

/**

             #@@@@                                         @@@@@            
           @@@@@@@@@.                                    @@@@@@@@@          
           @@@@@@@@@.                                    @@@@@@@@@          
           @@@@@@@@@.      @@@@@              %@@@@      @@@@@@@@@          
             #@@@@           @@@@@         @@@@@           @@@@@            
                                 @@@@@@@@@@@@                               
      /////////////                                        ////////////     
     ///////////////.                                   //////////////////  
    /////////////////                                   //////////////////  
    /////////////////                                    ////////////////   
      /////////////                                        ////////////     

*/

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IDescriptor.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IBattle.sol";

contract Finiliar is Ownable, ERC721, PaymentSplitter, IToken {
    using Strings for uint256;

    // Sale details
    uint256 public maxTokens = 1210; // presale amount
    uint256 public maxMintsPerTx = 20;
    uint256 public price = .06 ether; // presale price
    bool public saleActive;

    // When set, diverts tokenURI calls to external contract
    address public descriptor;
    // Only used when `descriptor` is 0x0
    string public baseURI;

    // Will be set when battle contract is deployed
    address public battleContract;

    uint256 private nextTokenId;

    // Admin access for privileged contracts
    mapping(address => bool) public admins;

    /**
     * @notice Caller must be owner or privileged admin contract.
     */
    modifier onlyAdmin() {
        require(owner() == _msgSender() || admins[msg.sender], "Not admin");
        _;
    }

    constructor(address[] memory payees, uint256[] memory shares)
      ERC721("Finiliar", "FINI")
      PaymentSplitter(payees, shares)
    {}

    /**
     * @dev Public mint.
     */
    function mint(uint256 quantity) external payable {
        require(saleActive, "Sale inactive");
        require(quantity <= maxMintsPerTx, "Too many mints per txn");
        require(nextTokenId + quantity <= maxTokens, "Exceeds max supply");
        require(msg.value >= price * quantity, "Not enough ether");
        require(msg.sender == tx.origin, "No contract mints");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, nextTokenId++);
        }
    }

    /**
     * @dev Return tokenURI directly or via alternative `descriptor` contract
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (descriptor == address(0)) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        } else {
            return IDescriptor(descriptor).tokenURI(tokenId);
        }
        
    }

    /**
     * @dev Simplified version of ERC721Enumberable's `totalSupply`
     */
    function totalSupply() external view returns (uint256) {
        return nextTokenId;
    }

    /**
     * @dev Set `descriptor` contract address to route `tokenURI`
     */
    function setDescriptor(address _descriptor) external onlyOwner {
        descriptor = _descriptor;
    }

    /**
     * @dev Set `battleContract` address to start disabling transfers during
     * battles.
     */
    function setBattleContract(address _contract) external onlyOwner {
        battleContract = _contract;
    }

    /**
     * @dev Set the `baseURI` used to construct `tokenURI`.
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @dev Enable increasing token supply.
     */
    function setMaxTokens(uint256 newMax) external onlyOwner {
        maxTokens = newMax;
    }

    /**
     * @dev Enable adjusting max mints per transaction.
     */
    function setMaxMintsPerTxn(uint256 newMax) external onlyOwner {
        maxMintsPerTx = newMax;
    }

    /**
     * @dev Enable adjusting price.
     */
    function setPrice(uint256 newPriceWei) external onlyOwner {
        price = newPriceWei;
    }

    /**
     * @dev Toggle sale status.
     */
    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    /**
     * @dev Toggle admin status for an address.
     */
    function setAdmin(address _address) external onlyOwner {
        admins[_address] = !admins[_address];
    }

    /**
     * @dev Admin mint. To be used in future expansions. New admin contract
     * must enforce mint mechanics.
     */
    function mintAdmin(uint256 quantity, address to) external override onlyAdmin {
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, nextTokenId++);
        }
    }

    /**
     * @dev Let battle contract transfer tokens
     */
    function battleTransfer(address from, address to, uint256 tokenId)
        external
        override
    {
        require(msg.sender == battleContract, "Not battle contract");
        ERC721._transfer(from, to, tokenId);
    }

    /**
     * @dev If a tokenId `isBattling`, disable transfers. Avoids gas costs of
     * escrowing tokens for battles. To bypass this pattern simply don't set
     * a `battleContract`.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override {
        // If we have a battle contract, check if this token is battling
        if (battleContract != address(0) && IBattle(battleContract).isBattling(tokenId)) {
            revert("Token is battling");
        } else {
            ERC721._transfer(from, to, tokenId);
        }
    }

}