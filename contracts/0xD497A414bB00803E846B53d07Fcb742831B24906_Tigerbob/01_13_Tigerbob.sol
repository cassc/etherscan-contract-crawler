// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

/*
 * @title – Tigerbob
 * @author – Matthew Wall
 */

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                            ▄▄▄▄▄      ▄                      ▄▄▄           //
//               ▐███▄                      ▐█▓              █████████  ▀██    ▓█▌    ▀█▌     ▐████           //
//            ▄████████▌  ██████▓   ▓█████▓ ▐██  ▀▓▓▌   ▓▓▓▌ ██     ▀▀       ▓█████   ▓███▓   ▐██▀            //
//            ███▀        ██   ▀█▓  ▓█▌     ▐██   ███▌  ██▌  ███▓▓▓▌    ▄▓▌  ██▌▐██▓  ▓████▓  ▐██             //
//           ███▌         ██ ▄▓██▀  ▓██▌▌▌▌▄▐██    ▐▀█▌██▀   ▀▀▀█████▌  ▓██ ██▓▌▓███  ▓█▌ ▀██████             //
//           ███▌  ▄█████ █████▀▀   ▓██▀▀▀▀ ▐██▄▄▄   ▀██▀    ▄    ▐███  ▓██ ██   ▐██▄ ▓█▌   █████▄            //
//            ███▄  ▄██▌  ██ ▀██▄▄  ▓█▌ ▄▄  ▐█████  ▐██▀     ██▄▄▄▓██   ▓██ ██▄    █▀ ▓█▌    ▀████            //
//            ▀███████▌   ██  ▐███  ▓█████▄        ▐██▀       ▀████▀▀        ▀        ▀▀                      //
//              ▐▀▀▀▀     ▀▀                      ▄▓█▀                                                        //
//                                                                                                            //
//                                                                                                            //
//                             ▐████▄                  ████▌                  ████▓                           //
//                 ████▄    ▄▌▓██▀▀▀██▌   ████▌    ▐▌▓██▀▀▀▓█▓   ▐███▓     ▌▌██▌▀▀▀█▓                         //
//                ████████▀▀     ▀  ▐▀▀▌ ████████▀▀     ▀   ▀▀▌ ████████▌▀▀    ▐   ▀▀▌▄                       //
//                ██▀  ▐███ ▀▀▀▀▀▄▄▀▀  ▀▄██▓   ███ ▐▀▀▀▀▄▄▌▀▀ ▀▄███▀  ███▌ ▀▀▀▀▌▄▌▀▀ ▀▌▄                      //
//             ▐▌▀▀▀       ▄▄▄▄▄▄▄  ▄▄▓█▀▀▀       ▄▄▄▄▄▄▄  ▐▄▄█▀▀▀▀      ▐▄▄▄▄▄▄▄  ▄▄▀▀▀▀▄                    //
//           ▄▀▀▄  █   ▐▀▀▀       ▀▀▄▀▀▄  █▄   ▀▀▀       ▀▀▌▄▀▄  ▐▌   ▀▀▀▀      ▐▀▀ ▄▀▀▀▀▀▀▄                  //
//           █ ▐▌  ▀▄▄▄▄    ▀▀▀▀▀   ▓▌▐█  ▀▄▄▄▄    ▐▀▀▀▀   ▐█ █  ▐▌▄▄▄     ▀▀▀▀     ▄▀▀▀▀▀▀▀▀▀▄ ▄             //
//           █  ▐▀▄▄▄ ▄▐▀▀▀▀▀▀▀▀▀▄  ▓▌  ▀▄▄▄▄ ▄▀▀▀▀▀▀▀▀▀▄  ▐█  ▀▄▄▄▄ ▄▀▀▀▀▀▀▀▀▀▄    █ ▀▀▀▀▀▀▀ █▄█             //
//           █▓▀▌▄    ▓▌ ▀▀▀▀▀▀▀ █  ▓█▀▀▄    ▐█ ▀▀▀▀▀▀▀ █  ▐█▀▀▄     █ ▀▀▀▀▀▀▀ █   ▄▀▀▀▀▀▀█▀▀▌▄▓ ▄            //
//            ▀▄ ▐▓▓▓  ▀▀▀▀▀▀▀▀▀▀ ▓  ▀▌  ▓▓▓▄  ▀▀▀▀▀▀▀▀▀ ▀▄ ▐▓  ▀▓▓▌ ▄▀▀▀▀▀▀▀▀▀ ▐▌       ▓  ▓▓▀   █           //
//              ▐▓▓   ▓██▀▓▓        ▄▓██▓▓   ▐██▀▓▓▄       ▐▓▓█▓▓▄   ██▀▀▓▌        ▓▓▓▓▄  ▓ ██▓▓▌▀            //
//                 ▀▀▀▀▐▓▓  █▌   ▓   ▀▀█▀ ▀▀▀▀█▓▓  ▐▌   ▓   ▀▀█▀  ▀▀▀█▓▓▄  █   ▄▄  ▀▀█▌     █▌                //
//                        ▀▄ ▐▀▄   ▀   ▄▀▄▄▀█▌   ▀▄▄ ▀▄   ▐▀  ▄▀▄▄▌▀█   ▀▀▄ ▀▄    ▀  ▄▀▀▄▄▀█                  //
//                          ▀▌▄ ▀▀▄▄▄██▀ ▄▀▌▌▀     ▀▀▄ ▀▀▄▄▄▄█▀ ▄▌▀▄▀      ▀▄ ▀▀▀▄▄▄█▀ ▐▄▀▄▀                  //
//                            ▀▀▀▄█ ▓█▄▄▀             ▀▀▄█▌▐█▄▄▀             ▀▀▄▓▌ █▄▄▀                       //
//                                 ▀                      ▀▀                     ▀▀                           //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Tigerbob is ERC721A, Ownable {
    using MerkleProof for bytes32[];

    /* ––– PUBLIC VARIABLES ––– */
    /*
     * @notice – Control switch for sale
     * @notice – Set by `setMintStage()`
     * @dev – 0 = PAUSED; 1 = ALLOWLIST, 2 = WAITLIST
     */
    enum MintStage {
        PAUSED,
        ALLOWLIST,
        WAITLIST
    }
    MintStage public _stage = MintStage.PAUSED;

    /*
     * @notice – Mint price in ether
     * @notice – Set by `setPrice()`
     */
    uint256 public _price = 0.25 ether;

    /*
     * @notice – Allowlist start timestamp
     * @notice – Set by `setAllowlistStartTimestamp()`
     */
    uint256 public _allowlistStartTimestamp;

    /*
     * @notice – Allowlist end timestamp
     * @notice – Set by `setAllowlistEndTimestamp()`
     */
    uint256 public _allowlistEndTimestamp;

    /*
     * @notice – Waitlist start timestamp
     * @notice – Set by `setWaitlistStartTimestamp()`
     */
    uint256 public _waitlistStartTimestamp;

    /*
     * @notice – Waitlist end timestamp
     * @notice – Set by `setWaitlistEndTimestamp()`
     */
    uint256 public _waitlistEndTimestamp;

    /*
     * @notice – MerkleProof root for verifying allowlist addresses
     * @notice – Set by `setRoot()`
     */
    bytes32 public _root;

    /*
     * @notice – Address to the project's gnosis safe
     * @notice – Set by `setSafe()`
     */
    address payable public _safe =
        payable(0x9a766555D4B815393a58e665909dd230b3745EFE);

    /*
     * @notice – Maximum token supply
     * @dev – Note this is constant and cannot be changed
     */
    uint256 public constant MAX_SUPPLY = 1_000;

    /*
     * @notice – Token URI base
     * @notice – Passed into constructor and also can be set by `setBaseURI()`
     */
    string public baseTokenURI;

    /* ––– END PUBLIC VARIABLES ––– */

    /* ––– INTERNAL FUNCTIONS ––– */
    /*
     * @notice – Internal function that overrides baseURI standard
     * @return – Returns newly set baseTokenURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /* ––– END INTERNAL FUNCTIONS ––– */

    /* ––– CONSTRUCTOR ––– */
    /*
     * @notice – Contract constructor
     * @param - newBaseURI : Token base string for metadata
     * @param – allowlistStartTimestamp: Timestamp that allowlist starts on
     * @param – allowlistEndTimestamp: Timestamp that allowlist ends on
     * @param – waitlistStartTimestamp: Timestamp that waitlist starts on
     * @param – waitlistEndTimestamp: Timestamp that waitlist ends on
     */
    constructor(
        string memory newBaseURI,
        uint256 allowlistStartTimestamp,
        uint256 allowlistEndTimestamp,
        uint256 waitlistStartTimestamp,
        uint256 waitlistEndTimestamp
    ) ERC721A("Tigerbob", "TGRBOB") {
        baseTokenURI = newBaseURI;
        _allowlistStartTimestamp = allowlistStartTimestamp;
        _allowlistEndTimestamp = allowlistEndTimestamp;
        _waitlistStartTimestamp = waitlistStartTimestamp;
        _waitlistEndTimestamp = waitlistEndTimestamp;
    }

    /* ––– END CONSTRUCTOR ––– */

    /* ––– MODIFIERS ––– */
    /*
     * @notice – Smart contract source check
     */
    modifier contractCheck() {
        require(tx.origin == msg.sender, "beep boop");
        _;
    }

    /*
     * @notice – Current mint stage check
     */
    modifier checkSaleActive() {
        require(MintStage.PAUSED != _stage, "sale not active");
        _;
    }

    /*
     * @notice – Token max supply boundary check
     */
    modifier checkMaxSupply(uint256 _amount) {
        require(totalSupply() + _amount <= MAX_SUPPLY, "exceeds total supply");
        _;
    }

    /*
     * @notice – Transaction value check
     */
    modifier checkTxnValue() {
        require(msg.value == _price, "invalid transaction value");
        _;
    }

    /*
     * @notice – Validates the merkleproof data
     */
    modifier validateProof(bytes32[] calldata _proof) {
        require(
            ERC721A._numberMinted(msg.sender) < 1,
            "wallet already claimed"
        );

        require(
            MerkleProof.verify(
                _proof,
                _root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "wallet not allowed"
        );

        _;
    }

    /* ––– END MODIFIERS ––– */

    /* ––– OWNER FUNCTIONS ––– */
    /*
     * @notice – Gifts an amount of tokens to a given address
     * @param – _to: Address to send the tokens to
     * @param – _amount: Amount of tokens to send
     */
    function gift(address _to, uint256 _amount)
        public
        onlyOwner
        checkMaxSupply(_amount)
    {
        _safeMint(_to, _amount);
    }

    /*
     * @notice – Sets the merkle root
     * @param – _newRoot: New root to set
     */
    function setRoot(bytes32 _newRoot) public onlyOwner {
        _root = _newRoot;
    }

    /*
     * @notice – Sets the Gnosis safe address
     * @param – _newSafe: New address for the team safe
     */
    function setSafe(address payable _newSafe) public onlyOwner {
        _safe = _newSafe;
    }

    /*
     * @notice – Sets the mint price (in wei)
     * @param – _newPrice: New mint price to set
     */
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    /*
     * @notice – Sets the allowlist start timestamp
     * @param – _newTime: New timestamp to set
     */
    function setAllowlistStartTimestamp(uint256 _newTime) public onlyOwner {
        _allowlistStartTimestamp = _newTime;
    }

    /*
     * @notice – Sets the allowlist end timestamp
     * @param – _newTime: New timestamp to set
     */
    function setAllowlistEndTimestamp(uint256 _newTime) public onlyOwner {
        _allowlistEndTimestamp = _newTime;
    }

    /*
     * @notice – Sets the waitlist start timestamp
     * @param – _newTime: New timestamp to set
     */
    function setWaitlistStartTimestamp(uint256 _newTime) public onlyOwner {
        _waitlistStartTimestamp = _newTime;
    }

    /*
     * @notice – Sets the waitlist start timestamp
     * @param – _newTime: New timestamp to set
     */
    function setWaitlistEndTimestamp(uint256 _newTime) public onlyOwner {
        _waitlistEndTimestamp = _newTime;
    }

    /*
     * @notice – Sets the mint stage
     * @param – _stage: {0 = PAUSED | 1 = ALLOWLIST | 2 = WAITLIST}
     */
    function setMintStage(MintStage _newStage) public onlyOwner {
        _stage = _newStage;
    }

    /*
     * @notice – Sets the base URI to the given string
     * @param – baseURI: New base URI to set
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    /*
     * @notice – Withdraws the contract balance to the safe
     */
    function withdrawToSafe() public onlyOwner {
        require(address(_safe) != address(0), "safe address not set");

        _safe.transfer(address(this).balance);
    }

    /*
     * @notice – Withdraws the contract balance to the safe
     */
    function withdrawToAny(address payable dest, uint256 amount)
        public
        onlyOwner
    {
        require(address(dest) != address(0), "cannot withdraw to null address");
        require(amount > 0, "cannot withdraw zero amount");

        dest.transfer(amount);
    }

    /* ––– END OWNER FUNCTIONS ––– */

    /* ––– PUBLIC FUNCTIONS ––– */
    /*
     * @notice – Mint function
     * @param _proof: MerkleProof data to validate
     */
    function mint(bytes32[] calldata _proof)
        public
        payable
        contractCheck
        checkSaleActive
        checkMaxSupply(1)
        checkTxnValue
        validateProof(_proof)
    {
        _safeMint(msg.sender, 1);
    }

    /* ––– END PUBLIC FUNCTIONS ––– */
}