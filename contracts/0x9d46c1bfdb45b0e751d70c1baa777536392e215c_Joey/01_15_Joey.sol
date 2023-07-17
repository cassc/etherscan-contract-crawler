// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./abstracts/xRooStaking.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Joey is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    event Incubated(uint64 indexed tokenId);
    event Unincubated(uint64 indexed tokenId);

    // ---------------------------------------- TOKEN VARIABLES --------------------------------------------------

    /**
     * Amount of seconds needed to incubate
     */
    uint64 public constant incubationTime = 12 weeks;

    /**
     * Max per transaction in the public/holder phase
     */
    uint64 public constant maxPerTransaction = 10;

    /**
     * The maximum supply for the token.
     * Will never exceed this supply.
     */
    uint64 public immutable maxSupply;

    /**
     * The wallet cap during the holderCapDuration
     */
    uint64 public walletCap = 3;

    /**
     * The quantity multiplier when using ROOLAH
     */
    uint64 public roolahMultiplier = 3;

    /**
     * The duration during which holders will have a wallet cap (post holderStart, in seconds)
     */
    uint64 public holderCapDuration;

    /**
     * The cost of minting (with a 3x multiplier) in ROOLAH
     *
     * @dev starts at 80 ROOLAH
     */
    uint256 public roolahCost = 80000000000000000000;

    /**
     * The cost of minting in ETH in the public mint
     *
     * @dev starts at 0.016942 ETH
     */
    uint256 public publicEthCost = 16942000000000000;

    /**
     * The cost of minting in ETH in the holder mint
     *
     * @dev starts at 0.01 ETH
     */
    uint256 public holderEthCost = 10000000000000000;

    /**
     * The start timestamp for minting with ROOLAH (UNIX SECONDS)
     */
    uint256 public roolahStart;

    /**
     * The start timestamp for holders (UNIX SECONDS)
     */
    uint256 public holderStart;

    /**
     * The start timestamp for the public mint (UNIX SECONDS)
     */
    uint256 public publicStart;

    /**
     * The ERC20 token contract that will be used
     * to pay to mint the token.
     */
    IERC20 public roolah;

    /**
     * The staking contract
     */
    xRooStaking public stakingContract;

    /**
     * The NFTX inventory staking xROO token
     */
    IERC20 public xROO;

    /**
     * The NFTX liquidity staking xROOWETH token
     */
    IERC20 public xROOWETH;

    /**
     * The NFTX vault token
     */
    IERC20 public ROO;

    /**
     * The RooTroop NFT
     */
    IERC721 public RooTroopNFT;

    /**
     * The baseURI for tokens
     */
    string private baseURI = "https://cc_nftstore.mypinata.cloud/ipfs/QmZDyvDm3W1q9259koCiQA3tBkNgwpdZxTY3ouRqvKKbD5/";

    /**
     * A mapping of token ID to time when incubation started (0 for never).
     */
    mapping(uint64 => uint256) public incubationTimestamp;

    /**
     * A mapping of token ID to time when incubation started (0 for never).
     */
    mapping(address => uint64) public numCappedMints;

    // ---------------------------------------- CONSTRUCTOR -------------------------------------------------------------

    /**
     * Deploys the contract and mints the first token to the deployer.
     *
     * @param _roolahMintStart - the start time of the ROOLAH mint (UNIX SECONDS)
     * @param _holderMintStart - the start time of the holder-only mint (UNIX SECONDS)
     * @param _publicMintStart - the start time of the public mint (UNIX SECONDS)
     * @param _walletCapDuration - the duration of wallet capping during the holder mint (UNIX SECONDS)
     * @param _roolahAddress - the address for the ROOLAH contract (payment token)
     * @param _stakingAddress - the address for xRooStaking
     * @param _rooTroopAddress - the address for RooTroopNFT
     * @param _xROOWETHAddress - the address for NFTX's xROOWETH
     * @param _xROOAddress - the address for NFTX's XROO
     * @param _ROOAddress - the address for NFTX's ROO vault token
     */
    constructor(
        uint64 _maxSupply,
        uint256 _roolahMintStart,
        uint256 _holderMintStart,
        uint256 _publicMintStart,
        uint64 _walletCapDuration,
        address _roolahAddress,
        address _stakingAddress,
        address _rooTroopAddress,
        address _xROOWETHAddress,
        address _xROOAddress,
        address _ROOAddress
    ) ERC721A("Joey", "JY") {
        maxSupply = _maxSupply;

        setAssociatedContracts(
            _roolahAddress,
            _stakingAddress,
            _rooTroopAddress,
            _xROOWETHAddress,
            _xROOAddress,
            _ROOAddress
        );

        setMintTimes(
            _roolahMintStart,
            _holderMintStart,
            _publicMintStart,
            _walletCapDuration
        );

        mintOwner(1, msg.sender, false);
    }

    // ------------------------------------------------ ADMINISTRATION LOGIC ------------------------------------------------

    /**
     * Sets the base URI for all immature tokens
     *
     * @dev be sure to terminate with a slash
     * @param uri - the target base uri (ex: 'https://google.com/')
     */
    function setBaseURI(string calldata uri) public onlyOwner {
        baseURI = uri;
    }

    /**
     * Sets the mint price
     *
     * @param _roolahMintCost - the mint cost for ROOLAH minting (with 18 decimal places).
     * @param _publicEthMintCost - the mint cost for ETH minting in public mint (GWEI)
     * @param _holderEthMintCost - the mint cost for ETH minting in holder mint (GWEI)
     * @param _roolahMultiplier - the quantity multiplier for using ROOLAH
     */
    function setMintPrice(
        uint256 _roolahMintCost,
        uint256 _holderEthMintCost,
        uint256 _publicEthMintCost,
        uint64 _roolahMultiplier
    ) external onlyOwner {
        roolahCost = _roolahMintCost;
        publicEthCost = _publicEthMintCost;
        holderEthCost = _holderEthMintCost;
        roolahMultiplier = _roolahMultiplier;
    }

    /**
     * Updates all mint times
     * @param _roolahMintStart - the start of the ROOLAH mint
     * @param _holderMintStart - the start of the holder-only mint
     * @param _walletCapDuration - the duration (in seconds) that the
     */
    function setMintTimes(
        uint256 _roolahMintStart,
        uint256 _holderMintStart,
        uint256 _publicMintStart,
        uint64 _walletCapDuration
    ) public onlyOwner {
        roolahStart = _roolahMintStart;
        holderStart = _holderMintStart;
        holderCapDuration = _walletCapDuration;
        publicStart = _publicMintStart;
    }

    function setAssociatedContracts(
        address _roolahAddress,
        address _stakingAddress,
        address _rooTroopAddress,
        address _xROOWETHAddress,
        address _xROOAddress,
        address _ROOAddress
    ) public onlyOwner {
        roolah = IERC20(_roolahAddress);
        stakingContract = xRooStaking(_stakingAddress);
        xROO = IERC20(_xROOAddress);
        xROOWETH = IERC20(_xROOWETHAddress);
        ROO = IERC20(_ROOAddress);
        RooTroopNFT = IERC721(_rooTroopAddress);
    }

    // ------------------------------------------------ URI LOGIC -------------------------------------------------

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // ------------------------------------------------ MINT LOGIC ------------------------------------------------

    /**
     * Allows the contract owner to mint for free and optionally incubate.
     *
     * @param _quantity - the number of tokens to mint
     * @param _autoIncubate - whether to automatically incubate minted tokens or not.
     * @param _to - the recipient.
     *
     * @dev Auto incubation as owner will bypass all waiting.
     */
    function mintOwner(
        uint64 _quantity,
        address _to,
        bool _autoIncubate
    ) public onlyOwner {
        uint64 offset = uint64(_currentIndex);

        // DISTRIBUTE THE TOKENS
        _safeMint(_to, _quantity);

        // INCUBATE
        if (_autoIncubate) {
            for (uint64 i; i < _quantity; i++) {
                _incubate(offset + i, true);
            }
        }
    }

    /**
     * Mints the given quantity of tokens provided it is possible to.
     * transfers the required number of ROOLAH from the user's wallet.
     *
     * @param _quantity - the number of tokens to mint
     * @param _autoIncubate - whether to automatically incubate minted tokens or not.
     */
    function mintROOLAH(uint64 _quantity, bool _autoIncubate)
        public
        nonReentrant
    {
        require(
            block.timestamp >= roolahStart && block.timestamp < holderStart,
            "Inactive"
        );
        uint256 remaining = maxSupply - _currentIndex;

        require(remaining > 0, "Mint over");
        require(_quantity >= 1, "Bad quantity");
        uint96 multipliedQuantity = roolahMultiplier * _quantity;

        require(multipliedQuantity <= remaining, "Not enough");
        uint64 offset = uint64(_currentIndex);

        roolah.transferFrom(msg.sender, address(this), _quantity * roolahCost);

        // DISTRIBUTE THE TOKENS
        _safeMint(msg.sender, multipliedQuantity);

        if (_autoIncubate) {
            for (uint64 i; i < multipliedQuantity; i++) {
                _incubate(offset + i, false);
            }
        }
    }

    /**
     * Mints the given quantity of tokens provided it is possible to.
     * Expects the appropriate amount of value transferred in ETH.
     *
     * @param _quantity - the number of tokens to mint
     * @param _autoIncubate - whether to automatically incubate minted tokens or not.
     */
    function mintETH(uint64 _quantity, bool _autoIncubate)
        public
        payable
        nonReentrant
    {
        require(block.timestamp >= holderStart, "Inactive");
        uint256 remaining = maxSupply - _currentIndex;

        require(remaining > 0, "Mint over");
        require(_quantity >= 1, "Bad quantity");
        require(_quantity <= remaining, "Not enough");
        uint256 cost = block.timestamp >= publicStart
            ? publicEthCost
            : holderEthCost;

        require(msg.value == _quantity * cost, "Bad value");
        uint64 offset = uint64(_currentIndex);

        if (block.timestamp < holderStart + holderCapDuration) {
            // IF CAPPED
            numCappedMints[msg.sender] += _quantity;
            require(numCappedMints[msg.sender] <= walletCap, "Exceeds limit");
        } else {
            require(_quantity <= maxPerTransaction, "Exceeds trans max");
        }

        require(
            (block.timestamp >= publicStart) || holdsEligibleToken(msg.sender),
            "Not holder"
        );

        // DISTRIBUTE THE TOKENS
        _safeMint(msg.sender, _quantity);

        // INCUBATE
        if (_autoIncubate) {
            for (uint64 i; i < _quantity; i++) {
                _incubate(offset + i, false);
            }
        }
    }

    // ------------------------------------------------ BURN LOGIC ------------------------------------------------

    /**
     * Burns the provided token id if you own it.
     * Reduces the supply by 1.
     *
     * @param tokenId - the ID of the token to be burned.
     */
    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not owner");

        _burn(tokenId);
    }

    // ------------------------------------------------ EXTERNAL INCUBATION LOGIC ------------------------------------------------

    /**
     * Checks to see if incubation is complete.
     * @return a boolean value indicating incubation completion.
     */
    function isMatured(uint64 _tokenId) external view returns (bool) {
        return _isMatured(_tokenId);
    }

    /**
     * Checks to see if a token is currently incubating.
     * @notice is false once the token has completed the incubation period.
     * @return a boolean value indicating the incubation status of the token.
     */
    function isIncubating(uint64 _tokenId) external view returns (bool) {
        return _isIncubating(_tokenId);
    }

    /**
     * Adds the given token to the incubator. The contract owner needn't wait for incubation to complete.
     * @param _tokenId the ID of the token to incubate.
     * @notice you must own the _tokenId provided to incubate.
     */
    function incubate(uint64 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Not owner");
        require(incubationTimestamp[_tokenId] == 0, "Incubated");

        _incubate(_tokenId, msg.sender == owner());
    }

    /**
     * Removes the given token from the incubator.
     * @param _tokenId the ID of the token to unincubate.
     * @notice you must own the _tokenId provided to incubate. Will fail if the token is not incubating.
     */
    function unincubate(uint64 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Not owner");
        require(_isIncubating(_tokenId), "Not incubated");

        _unincubate(_tokenId);
    }

    // ----------------------------------- INTERNAL INCUBATION LOGIC -----------------------------------

    /**
     * Checks to see if incubation is complete.
     * @return a boolean value indicating incubation completion.
     */
    function _isMatured(uint64 _tokenId) internal view returns (bool) {
        if (incubationTimestamp[_tokenId] == 0) return false;

        return
            (block.timestamp - incubationTimestamp[_tokenId]) >= incubationTime;
    }

    /**
     * Checks to see if a token is currently incubating.
     * @notice is false once the token has completed the incubation period.
     * @return a boolean value indicating the incubation status of the token.
     */
    function _isIncubating(uint64 _tokenId) internal view returns (bool) {
        if (_isMatured(_tokenId)) return false;
        return incubationTimestamp[_tokenId] != 0;
    }

    /**
     * Adds the given token to the incubator. The contract owner needn't wait for incubation to complete.
     * @param _tokenId the ID of the token to incubate.
     * @param _matureCompletely indicates if the token should be matured immediately
     * @dev does not check ownership/current incubation status
     */
    function _incubate(uint64 _tokenId, bool _matureCompletely) internal {
        incubationTimestamp[_tokenId] = _matureCompletely
            ? block.timestamp - incubationTime
            : block.timestamp;

        emit Incubated(_tokenId);
    }

    /**
     * Adds the given token to the incubator. The contract owner needn't wait for incubation to complete.
     * @param _tokenId the ID of the token to unincubate.
     * @dev does not check ownership/current incubation status.
     */
    function _unincubate(uint64 _tokenId) internal {
        incubationTimestamp[_tokenId] = 0;

        emit Unincubated(_tokenId);
    }

    /**
     * A handler to execute before transfering a token to another wallet.
     * @dev resets the incubation status on transfer.
     */
    function _beforeTokenTransfers(
        address,
        address,
        uint256 tokenId,
        uint256 amount
    ) internal override {
        // bulk transfers only happen on mint, and tokens minted are not incubated.
        if (amount == 1 && _isIncubating(uint64(tokenId)))
            _unincubate(uint64(tokenId));
    }

    // ------------------------------------------------ BALANCE STUFFS ------------------------------------------------

    /**
     * Indicates if a user holds a token that will allow access into
     * the gated mint.
     *
     * @param user - the user whose balances are being checked.
     */
    function holdsEligibleToken(address user) public view returns (bool) {
        (uint256 stake, , , , , ) = stakingContract.users(user);

        return
            (RooTroopNFT.balanceOf(user) > 0) ||
            (stake > 0) ||
            (ROO.balanceOf(user) > 0) ||
            (xROOWETH.balanceOf(user) > 0) ||
            (xROO.balanceOf(user) > 0);
    }

    /**
     * Withdraws balance in ROOLAH/ETH from the contract to the owner (sender).
     */
    function withdraw() external onlyOwner {
        roolah.transfer(msg.sender, roolah.balanceOf(address(this)));
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Trans failed");
    }

    // ----------------------------------------------- USEFUL STUFFS ---------------------------------------------

    /**
     * A helper function that will just spill out
     * any and all pertinent data for a frontend.
     */
    function dumpMintData()
        public
        view
        returns (
            uint64 _incubationTime,
            uint64 _maxPerTransaction,
            uint64 _maxSupply,
            uint64 _walletCap,
            uint64 _roolahMultiplier,
            uint64 _holderCapDuration,
            uint256 _roolahCost,
            uint256 _publicEthCost,
            uint256 _holderEthCost,
            uint256 _roolahStart,
            uint256 _holderStart,
            uint256 _publicStart
        )
    {
        return (
            incubationTime,
            maxPerTransaction,
            maxSupply,
            walletCap,
            roolahMultiplier,
            holderCapDuration,
            roolahCost,
            publicEthCost,
            holderEthCost,
            roolahStart,
            holderStart,
            publicStart
        );
    }

    /**
     * The receive function, does nothing
     */
    receive() external payable {
        // NOTHING TO SEE HERE
    }
}