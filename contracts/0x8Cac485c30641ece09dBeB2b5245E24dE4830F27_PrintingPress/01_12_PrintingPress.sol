// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "./IEulerBeats.sol";
import "hardhat/console.sol";



// The printing press for the EulerBeats token contract.  This contract is responsible
// for minting and burning EulerBeat prints.  
// To be functional, this must be set as the owner of the original EulerBeats contract, 
// and the EulerBeats contract should be disabled.  After that, this is the only
// way to print those fresh beats.
contract PrintingPress is Ownable, ERC1155Holder, ReentrancyGuard {
    using SafeMath for uint256;

    /***********************************|
    |        Variables and Events       |
    |__________________________________*/
    
    bool public burnEnabled = false;
    bool public printEnabled = false;

    // Supply restriction on seeds/original NFTs
    uint256 constant MAX_SEEDS_SUPPLY = 27;

    // The 40 bit is flag to distinguish prints - 1 for print
    uint256 constant PRINTS_FLAG_BIT = 1 << 39;

    // PrintingPress EulerBeats wrapper specific storage
    address public EulerBeats;
    mapping (uint => uint) public seedToPrintId;

    /**
     * @dev Function to return the seedIds in an iterable array of uints
     */
    function getSeedIds() public pure returns (uint256[MAX_SEEDS_SUPPLY] memory seedIds){
        seedIds = [
            uint256(21575894274),
            uint256(18052613891),
            uint256(12918588162),
            uint256(21760049923),
            uint256(22180136451),
            uint256(8926004995),
            uint256(22364095747),
            uint256(17784178691),
            uint256(554240256),
            uint256(17465084160),
            uint256(13825083651),
            uint256(12935627264),
            uint256(8925938433),
            uint256(4933026051),
            uint256(8673888000),
            uint256(13439075074),
            uint256(13371638787),
            uint256(17750625027),
            uint256(21592343040),
            uint256(4916052483),
            uint256(4395697411),
            uint256(13556253699),
            uint256(470419715),
            uint256(17800760067),
            uint256(9193916675),
            uint256(9395767298),
            uint256(22314157057)
        ];
    }


    constructor(address _parent) {
        EulerBeats = _parent;

        uint256[MAX_SEEDS_SUPPLY] memory seedIds = getSeedIds();

        for (uint256 i = 0; i < MAX_SEEDS_SUPPLY; i++) {
            // Set the valid original seeds and hard-code their corresponding print tokenId
            seedToPrintId[seedIds[i]] = getPrintTokenIdFromSeed(seedIds[i]);
        }
    }


    /***********************************|
    |        User Interactions          |
    |__________________________________*/

    /**
     * @dev Function to correct a seedToOwner value if incorrect, before royalty paid
     * @param seed The NFT id to mint print of
     * @param _owner The current on-chain owner of the seed
     */
    function ensureEulerBeatsSeedOwner(uint256 seed, address _owner) public {
        require(seedToPrintId[seed] > 0, "Seed does not exist");
        require(IEulerBeats(EulerBeats).balanceOf(_owner, seed) == 1, "Incorrect seed owner");

        address registeredOwner = IEulerBeats(EulerBeats).seedToOwner(seed);

        if (registeredOwner != _owner) {
            IEulerBeats(EulerBeats).safeTransferFrom(address(this), _owner, seed, 0, hex"");
            require(IEulerBeats(EulerBeats).seedToOwner(seed) == _owner, "Invalid seed owner");
        }
    }

    /**
     * @dev Function to mint prints from an existing seed. Msg.value must be sufficient.
     * @param seed The NFT id to mint print of
     * @param _owner The current on-chain owner of the seed
     */
    function mintPrint(uint256 seed, address payable _owner)
        public
        payable
        nonReentrant
        returns (uint256)
    {
        require(printEnabled, "Printing is disabled");

        // Record initial balance minus msg.value (difference to be refunded to user post-print)
        uint preCallBalance = address(this).balance.sub(msg.value);

        // Test that seed is valid
        require(seedToPrintId[seed] > 0, "Seed does not exist");

        // Verify owner of seed & ensure royalty ownership
        ensureEulerBeatsSeedOwner(seed, _owner);

        // Get print tokenId from seed
        uint256 tokenId = seedToPrintId[seed];

        // Enable EB.mintPrint
        IEulerBeats(EulerBeats).setEnabled(true);

        // EB.mintPrint(), let EB check price and refund to address(this)
        IEulerBeats(EulerBeats).mintPrint{value: msg.value}(seed);

        // Disable EB.mintPrint
        IEulerBeats(EulerBeats).setEnabled(false);

        // Transfer print to msg.sender
        IEulerBeats(EulerBeats).safeTransferFrom(address(this), msg.sender, tokenId, 1, hex"");

        // Send to user difference between current and preCallBalance if nonzero amt
        uint refundBalance = address(this).balance.sub(preCallBalance);
        if (refundBalance > 0) {
            (bool success, ) = msg.sender.call{value: refundBalance}("");
            require(success, "Refund payment failed");
        }
        
        return tokenId;
    }

    /**
     * @dev Function to burn a print
     * @param seed The seed for the print to burn.
     * @param minimumSupply The minimum token supply for burn to succeed, this is a way to set slippage. 
     * Set to 1 to allow burn to go through no matter what the price is.
     */
    function burnPrint(uint256 seed, uint256 minimumSupply) public nonReentrant {
        require(burnEnabled, "Burning is disabled");
        uint startBalance = address(this).balance;

        // Check that seed is one of hard-coded 27
        require(seedToPrintId[seed] > 0, "Seed does not exist");

        // Get token id for prints
        uint256 tokenId = seedToPrintId[seed];

        // Transfer 1 EB print @ tokenID from msg.sender to this contract (requires approval)
        IEulerBeats(EulerBeats).safeTransferFrom(msg.sender, address(this), tokenId, 1, hex"");

        // Enable EulerBeats
        IEulerBeats(EulerBeats).setEnabled(true);

        // Burn print on v1, should receive the funds here
        IEulerBeats(EulerBeats).burnPrint(seed, minimumSupply);

        // Disable EulerBeats
        IEulerBeats(EulerBeats).setEnabled(false);

        (bool success, ) = msg.sender.call{value: address(this).balance.sub(startBalance)}("");
        require(success, "Refund payment failed");
    }


    /***********************************|
    |        Admin                      |
    |__________________________________*/

    /**
     * Should never be a balance here, only via selfdestruct
     * @dev Withdraw earned funds from original Nft sales and print fees. Cannot withdraw the reserve funds.
     */
    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    /**
     * @dev Function to enable/disable printing
     * @param _enabled The flag to turn printing on or off
     */
    function setPrintEnabled(bool _enabled) public onlyOwner {
        printEnabled = _enabled;
    }

    /**
     * @dev Function to enable/disable burning prints
     * @param _enabled The flag to turn burning on or off
     */
    function setBurnEnabled(bool _enabled) public onlyOwner {
        burnEnabled = _enabled;
    }

    /**
     * @dev The token id for the prints contains the seed/original NFT id
     * @param seed The seed/original NFT token id
     */
    function getPrintTokenIdFromSeed(uint256 seed) internal pure returns (uint256) {
        return seed | PRINTS_FLAG_BIT;
    }


    /***********************************|
    |        Admin  - Passthrough       |
    |__________________________________*/
    // methods that can access onlyOwner methods of EB contract, must be onlyOwner

    /**
     * @dev Function to transfer ownership of the EB contract
     * @param newowner Address to set as the new owner of EB
     */
    function transferOwnershipEB(address newowner) public onlyOwner {
        IEulerBeats(EulerBeats).transferOwnership(newowner);
    }

    /**
     * @dev Function to enable/disable mintPrint and burnPrint on EB contract
     * @param enabled Bool value for setting whether EB is enabled
     */
    function setEnabledEB(bool enabled) public onlyOwner {
        IEulerBeats(EulerBeats).setEnabled(enabled);
    }

    /**
     * @dev Function to withdraw Treum fee balance from EB contract
     */
    function withdrawEB() public onlyOwner {
        IEulerBeats(EulerBeats).withdraw();
        msg.sender.transfer(address(this).balance);
    }

    /**
     * @dev Set the base metadata uri on the EB contract
     * @param newuri The new base uri
     */
    function setURIEB(string memory newuri) public onlyOwner {
        IEulerBeats(EulerBeats).setURI(newuri);
    }

    /**
     * @dev Reset script count in EB
     */
    function resetScriptCountEB() public onlyOwner {
        IEulerBeats(EulerBeats).resetScriptCount();
    }

    /**
     * @dev Add script string to EB
     * @param _script String chunk of EB music gen code
     */
    function addScriptEB(string memory _script) public onlyOwner {
        IEulerBeats(EulerBeats).addScript(_script);
    }

    /**
     * @dev Update script at index
     * @param _script String chunk of EB music gen code
     * @param index Index of the script which will be updated
     */
    function updateScriptEB(string memory _script, uint256 index) public onlyOwner {
        IEulerBeats(EulerBeats).updateScript(_script, index);
    }

    /**
     * @dev Locks ability to check scripts in EB, this is irreversible
     * @param locked Bool value whether to lock the script updates
     */
    function setLockedEB(bool locked) public onlyOwner {
        IEulerBeats(EulerBeats).setLocked(locked);
    }

    // Need payable fallback to receive ETH from burns, withdraw, etc
    receive() external payable {
        // WARNING: this does not prevent selfdestruct ETH transfers
        require(msg.sender == EulerBeats, "Only EulerBeats allowed to send ETH here");
    }
}