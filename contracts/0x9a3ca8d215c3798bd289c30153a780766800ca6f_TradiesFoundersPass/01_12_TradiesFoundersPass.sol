// SPDX-License-Identifier: MIT

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@                                          %%%%%%%%%%%%            %%%%%%%%#*.               @@@@
// @@@@     ,#%%%%%%%%&(%%%%%%%%%/      %%%%%.   %%%%%%%%%%%%%%*/*%%%*# (%%%%.*.*#%%%#%%%%%%%%%%   @@@@
// @@@@ %%%%%%%%%%%%*  (%%,%%&%%%%%/   %%%%%%%(/ %%%%%      *%%%%%%%%#% %%%%%      %%%%%%%#%%.%/   @@@@
// @@@@      *%%%&#   %%%%%     %%%%% %%%%% %%%%&(%%%%       %%%%&.%%&% %%%%%%%%%%%% %%%%          @@@@
// @@@@       %%%%%  .%%%%%%%%%%%%%,%%%%%%   %%%%% %%%      %%%%.*%%%%% %%%%%       ,%#%%%%%%%%%   @@@@
// @@@@       %%%%/* %%%%%%%%%%%%%, %%%%%%%%%%%%%%% %%%%%%%%%%,%  %%%%% %%%%%%%%%&%/,       %%%%,  @@@@
// @@@@        %%%%& %%%%#   %%%%% %%%%%       %%%%*   .,*.       %%%%( ,(%%&%(*.*###&%%%%%%%%%.%  @@@@
// @@@@        %%&#*          /%/.. .                                                #%%%%%%%(     @@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Tradies Founders Pass
 * @author @jonathansnow
 * @notice Tradies Founders Pass is an ERC721 token that provides access to the Tradies ecosystem.
 */
contract TradiesFoundersPass is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;

    string private _baseTokenURI;

    uint256 public constant TEAM_SUPPLY = 20;
    uint256 public constant MAX_SUPPLY = 400;
    uint256 public constant MAX_MINT = 3;
    uint256 public constant PRICE = 0.15 ether;

    bool public saleIsActive;
    bool public saleIsLocked;

    mapping (address => uint256) public mintBalance;

    address public a1 = 0xa238Db3aE883350DaDa3592345e8A0d318b06e82;          // Treasury
    address public constant a2 = 0xCAe379DD33Cc01D276E57b40924C20a8312197AA; // Dev
    address public constant a3 = 0x46CeDbDf6D4E038293C66D9e0E999A5e97a5119C; // Team

    constructor() ERC721("TradiesFoundersPass", "TDFP") {
        _nextTokenId.increment();   // Start Token Ids at 1
    }

    /**
     * @notice Public minting function for whitelisted addresses
     * @dev Sale must be active, sale must not be locked, and minter must not mint more than 3 tokens..
     * @param quantity the number of tokens to mint
     */
    function mint(uint256 quantity) public payable {
        require(saleIsActive, "Sale is not active yet.");
        require(!saleIsLocked , "Sale is closed.");
        require(quantity > 0, "Must mint more than 0.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max available.");
        require(mintBalance[msg.sender] + quantity <= MAX_MINT, "No mints remaining.");
        require(msg.value == quantity * PRICE, "Wrong ETH value sent.");

        mintBalance[msg.sender] += quantity;

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    /**
     * @notice Get the number of passes minted
     * @return uint256 number of passes minted
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    /**
     * @notice Get baseURI
     * @dev Overrides default ERC721 _baseURI()
     * @return baseURI the base token URI for the collection
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Update the baseURI
     * @dev URI must include trailing slash
     * @param baseURI the new metadata URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Toggle public sale on/off
     */
    function toggleSale() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * @notice Permanently disable the public sale
     * @dev This is a supply shrink mechanism in the event we want to permanently prevent further minting.
     */
    function disableSale() external onlyOwner {
        saleIsLocked = true;
    }

    /**
     * @notice Admin minting function
     * @dev Allows the team to mint up to 20 tokens. The tokens must be minted prior to public sale.
     * @param quantity the number of tokens to mint
     * @param recipient the address to mint the tokens to
     */
    function adminMint(uint256 quantity, address recipient) public onlyOwner {
        require(totalSupply() + quantity <= TEAM_SUPPLY, "Exceeds max team amount.");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(recipient, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    /**
     * @notice Update the Treasury address
     * @dev Allows the team to update the address they will use to receive Treasury funds.
     */
    function updateTreasury(address newAddress) external onlyOwner {
        a1 = newAddress;
    }

    /**
     * @notice Function to withdraw funds from the contract with splits
     * @dev Transfers 92% of the contract ETH balance to the Treasury address, 5% to dev partner, and 3% to the
     * mod Gnosis wallet. Any balance remaining after the split transfers will be sent to the Treasury.
     */
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        
        _withdraw(a1, (balance * 92) / 100 );   // 92%
        _withdraw(a2, (balance * 5) / 100 );    // 5%
        _withdraw(a3, (balance * 3) / 100 );    // 3%
        _withdraw(a1, address(this).balance );  // Remainder
    }

    /**
     * @notice Function to send ETH to a specific address
     * @dev Using call to ensure that transfer will succeed for both EOA and Gnosis Addresses.
     */
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = payable(_address).call{ value: _amount }("");
        require(success, "Transfer failed");
    }

}