// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./tokens/ERC721.sol";
import "./tokens/ERC20.sol";
import "./utils/owner.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RapPearsNft is ERC721, Owner {
    using Strings for *;
    ///=============================================================================================
    /// Data Struct
    ///=============================================================================================

    struct Rewards {
        uint256 weight;
        uint256 tracker; //sum of delta(deposit) * yeildPerDeposit || SCALED
    }

    struct MetaData {
        string name;
        address vaultAddress;
        uint256 withdrawable;
        uint256 id;
        uint256 vaultType;
    }

    ///=============================================================================================
    /// Accounting State
    ///=============================================================================================

    // tokenID => Deposits
    mapping(uint256 => Rewards) public deposits;

    //sum of yeild/totalWeight scaled by SCALAR
    uint256 public yeildPerDeposit;

    uint256 public totalWeight;

    uint256 constant SCALAR = 1e10;

    ///=============================================================================================
    /// Rappears
    ///=============================================================================================

    // tokenId => lockUp timestamp
    mapping(uint256 => uint256) locked;
    uint256 internal lockTimeSeconds;

    mapping(uint256 => mapping(address => bool)) public privateMintClaimed;

    mapping(uint256 => mapping(uint256 => uint256)) public qtyPricing;
    uint256 public defaultPricePerUnit = 1e17;
    uint256 public pricingVersionCount = 1;

    uint256 public maxWhitelistMintPerTx;

    bool internal publicMint;
    uint256 internal supplyCap;

    mapping(address => uint256[]) public tokensByAddress;

    // returns the current index in the tokensByAddress array
    mapping(uint256 => uint256) internal indexById;

    ///=============================================================================================
    /// Misc
    ///=============================================================================================

    ERC20 public weth;

    uint256 internal devFeeBP;

    uint256 public devBalance;

    uint256 public currentId;

    ///=============================================================================================
    /// External Logic
    ///=============================================================================================

    constructor(
        address _weth,
        uint256 _devFeeBP,
        uint256 _lockTime,
        uint256 _initalSupplyCap,
        uint256 _initialMintAmount,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        weth = ERC20(_weth);
        devFeeBP = _devFeeBP;
        lockTimeSeconds = _lockTime;
        supplyCap = _initalSupplyCap;
        setMaxWhiteList(5);
        ipfsLink = "ipfs://QmWYt6XezHy7PBwCYEHpWZYfSemjGwWMpHSxRmXVfSFEvQ/";
        maxWhitelistMintPerTx = 5;

        for (uint256 i; i < _initialMintAmount; ) {
            _mintNewNFT();
            unchecked {
                ++i;
            }
        }
    }

    function adminMint(uint256 amount)
        external
        onlyOwner
        returns (uint256[] memory)
    {
        _takeFees();
        uint256[] memory ret = new uint256[](amount);

        for (uint256 i; i < amount; ) {
            ret[i] = _mintNewNFT();
            // unlikely to overflow
            unchecked {
                ++i;
            }
        }
        return ret;
    }

    function mintNewNft(uint256 amount)
        external
        payable
        returns (uint256[] memory)
    {
        require(price(amount) <= msg.value, "underpaid");
        require(publicMint, "not live");

        _takeFees();

        uint256[] memory ret = new uint256[](amount);

        for (uint256 i; i < amount; ) {
            ret[i] = _mintNewNFT();

            // unlikely to overflow
            unchecked {
                ++i;
            }
        }

        return ret;
    }

    function lockUp(uint256 id) external {
        require(msg.sender == ownerOf(id), "Not Owner");

        locked[id] = block.timestamp;
        deposits[id].weight = 100; // 100 = 1 weight
        deposits[id].tracker += 100 * yeildPerDeposit;
        totalWeight += 100;
    }

    event A(uint256);

    function withdrawFromId(uint256 id, uint256 amount) public {
        require(
            block.timestamp - locked[id] >= lockTimeSeconds && locked[id] != 0,
            "here"
        );

        locked[id] = 0;

        _withdrawFromId(amount, id);
    }

    function bundleWithdraw() external {
        uint256 length = tokensByAddress[msg.sender].length;
        for (uint256 i; i < length; ) {
            uint256 id = tokensByAddress[msg.sender][i];
            if (
                block.timestamp - locked[id] >= lockTimeSeconds &&
                locked[id] != 0
            ) {
                withdrawFromId(id, withdrawableById(id));
            }
            unchecked {
                ++i;
            }
        }
    }

    function withdrawableById(uint256 id)
        public
        view
        returns (uint256 claimId)
    {
        return yieldPerId(id);
    }

    function claimDevFeeBPs() external onlyOwner {
        weth.transfer(owner, devBalance);
    }

    ///=============================================================================================
    /// Internal Logic
    ///=============================================================================================

    function _mintNewNFT() internal returns (uint256) {
        uint256 id = ++currentId;
        require(currentId <= supplyCap);

        _mint(msg.sender, id);
        _addId(msg.sender, id);

        return id;
    }

    function _withdrawFromId(uint256 amount, uint256 id) internal {
        require(msg.sender == ownerOf(id) && amount <= withdrawableById(id));

        deposits[id].weight = 0; // user ceases to earn yield
        deposits[id].tracker = 0;
        totalWeight -= 100;

        weth.transfer(msg.sender, amount);
    }

    function _takeFees() internal {
        // grieifing is a non issue here
        (bool success, ) = payable(address(weth)).call{value: msg.value}("");
        require(success);

        uint256 toDev = (msg.value * devFeeBP) / 10000;
        devBalance += toDev;

        if (totalWeight > 0) {
            distributeYeild(msg.value - toDev);
        } else {
            devBalance += (msg.value - toDev);
        }
    }

    // add to list of ID by address
    function _addId(address who, uint256 id) internal {
        tokensByAddress[who].push(id);

        indexById[id] = tokensByAddress[who].length - 1;
    }

    // remove from list of id by address
    function _removeId(address who, uint256 id) internal {
        uint256 index = indexById[id]; // get index of value to remove

        uint256 lastVal = tokensByAddress[who][tokensByAddress[who].length - 1]; // get last val from array

        tokensByAddress[who][index] = lastVal; // set last value to remove index of value to remove

        tokensByAddress[who].pop(); //pop off the now duplicate value
    }

    ///=============================================================================================
    /// Yield
    ///=============================================================================================

    function distributeYeild(uint256 amount) public virtual {
        yeildPerDeposit += ((amount * SCALAR) / totalWeight);
    }

    function yieldPerId(uint256 id) public view returns (uint256) {
        uint256 pre = (deposits[id].weight * yeildPerDeposit) / SCALAR;
        return pre - (deposits[id].tracker / SCALAR);
    }

    ///=============================================================================================
    /// Pricing
    ///=============================================================================================

    function price(uint256 _count) public view returns (uint256) {
        uint256 pricePerUnit = qtyPricing[pricingVersionCount][_count];
        // Mint more than max discount reverts to max discount
        if (_count > maxWhitelistMintPerTx) {
            pricePerUnit = qtyPricing[pricingVersionCount][
                maxWhitelistMintPerTx
            ];
        }
        // Minting an undefined discount price uses defaults price
        if (pricePerUnit == 0) {
            pricePerUnit = defaultPricePerUnit;
        }
        return pricePerUnit * _count;
    }

    ///=============================================================================================
    /// Whitelist
    ///=============================================================================================

    function whitelistMint(
        uint256 amount,
        uint256 whitelistNonce,
        bytes32 msgHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable returns (uint256[] memory) {
        require(msg.value >= price(amount), "Value below price");
        require(
            !privateMintClaimed[whitelistNonce][msg.sender],
            "Already claimed!"
        );

        // Security check.
        bytes32 calculatedMsgHash = keccak256(
            abi.encodePacked(msg.sender, whitelistNonce)
        );

        address signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)
            ),
            _v,
            _r,
            _s
        );
        require(calculatedMsgHash == msgHash, "Invalid hash");
        require(owner == signer, "Access denied");

        // Let's mint!
        privateMintClaimed[whitelistNonce][msg.sender] = true;

        _takeFees();

        uint256[] memory ret = new uint256[](amount);

        for (uint256 i; i < amount; ) {
            ret[i] = _mintNewNFT();
            // unlikely to overflow
            unchecked {
                ++i;
            }
        }

        return ret;
    }

    ///=============================================================================================
    /// Setters
    ///=============================================================================================

    function setLockTime(uint256 _lockTime) external onlyOwner {
        lockTimeSeconds = _lockTime;
    }

    function setMaxWhiteList(uint256 amount) public onlyOwner {
        maxWhitelistMintPerTx = amount;
    }

    function setMintPrices(
        uint256 _defaultPricePerUnit,
        uint256[] memory qty,
        uint256[] memory prices
    ) public onlyOwner {
        require(
            qty.length == prices.length,
            "Qty input vs price length mismatch"
        );
        defaultPricePerUnit = _defaultPricePerUnit;
        ++pricingVersionCount;

        bool containsMaxWhitelistMintPerTx = false;
        for (uint256 i = 0; i < qty.length; i++) {
            if (qty[i] == maxWhitelistMintPerTx) {
                containsMaxWhitelistMintPerTx = true;
            }
            qtyPricing[pricingVersionCount][qty[i]] = prices[i];
        }
        require(
            containsMaxWhitelistMintPerTx,
            "prices do not include the max mint price"
        );
    }

    function setSupplyCap(uint256 total) external onlyOwner {
        supplyCap = total;
    }

    function setPublicMint(bool open) external onlyOwner {
        publicMint = open;
    }

    ///=============================================================================================
    /// Overrides
    ///=============================================================================================

    string public ipfsLink;

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        return string(abi.encodePacked(ipfsLink, tokenId.toString(), ".json"));
    }

    function setTokenUri(string memory baseURI) public onlyOwner {
        ipfsLink = baseURI;
    }

    function totalSupply() public view returns (uint256) {
        return supplyCap;
    }


    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(
            locked[id] == 0 || locked[id] - block.timestamp >= lockTimeSeconds
        );

        locked[id] = 0;

        _removeId(from, id);
        _addId(to, id);

        super.transferFrom(from, to, id);
    }
}