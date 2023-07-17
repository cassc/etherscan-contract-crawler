pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract TokenRecover is Ownable {
    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        onlyOwner
    {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

// Interface for our erc20 token
interface IMuseToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function mintingFinished() external view returns (bool);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

/*
 * Deployment checklist::
 *  1. Deploy all contracts
 *  2. Give minter role to the claiming contract
 *  3. Add objects (most basic cost 5 and give 1 day and 1 score)
 *  4.
 */

// ERC721,
contract VNFT is
    Ownable,
    ERC721PresetMinterPauserAutoId,
    TokenRecover,
    ERC1155Holder
{
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    IMuseToken public muse;

    struct VNFTObj {
        address token;
        uint256 id;
        uint256 standard; //the type
    }

    // Mapping from token ID to NFT struct details
    mapping(uint256 => VNFTObj) public vnftDetails;

    // max dev allocation is 10% of total supply
    uint256 public maxDevAllocation = 100000 * 10**18;
    uint256 public devAllocation = 0;

    // External NFTs
    struct NFTInfo {
        address token; // Address of LP token contract.
        bool active;
        uint256 standard; //the nft standard ERC721 || ERC1155
    }

    NFTInfo[] public supportedNfts;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemIds;

    // how many tokens to burn every time the VNFT is given an accessory, the remaining goes to the community and devs
    uint256 public burnPercentage = 90;
    uint256 public giveLifePrice = 5 * 10**18;

    uint256 public fatalityPct = 60;

    bool public gameStopped = false;

    // mining tokens
    mapping(uint256 => uint256) public lastTimeMined;

    // VNFT properties
    mapping(uint256 => uint256) public timeUntilStarving;
    mapping(uint256 => uint256) public vnftScore;
    mapping(uint256 => uint256) public timeVnftBorn;

    // items/benefits for the VNFT could be anything in the future.
    mapping(uint256 => uint256) public itemPrice;
    mapping(uint256 => uint256) public itemPoints;
    mapping(uint256 => string) public itemName;
    mapping(uint256 => uint256) public itemTimeExtension;

    // mapping(uint256 => address) public careTaker;
    mapping(uint256 => mapping(address => address)) public careTaker;

    event BurnPercentageChanged(uint256 percentage);
    event ClaimedMiningRewards(uint256 who, address owner, uint256 amount);
    event VnftConsumed(uint256 nftId, address giver, uint256 itemId);
    event VnftMinted(address to);
    event VnftFatalized(uint256 nftId, address killer);
    event ItemCreated(uint256 id, string name, uint256 price, uint256 points);
    event LifeGiven(address forSupportedNFT, uint256 id);
    event Unwrapped(uint256 nftId);
    event CareTakerAdded(uint256 nftId, address _to);
    event CareTakerRemoved(uint256 nftId);

    constructor(address _museToken)
        public
        ERC721PresetMinterPauserAutoId(
            "VNFT",
            "VNFT",
            "https://gallery.verynify.io/api/"
        )
    {
        _setupRole(OPERATOR_ROLE, _msgSender());
        muse = IMuseToken(_museToken);
    }

    modifier notPaused() {
        require(!gameStopped, "Contract is paused");
        _;
    }

    modifier onlyOperator() {
        require(
            hasRole(OPERATOR_ROLE, _msgSender()),
            "Roles: caller does not have the OPERATOR role"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Roles: caller does not have the MINTER role"
        );
        _;
    }

    function contractURI() public pure returns (string memory) {
        return "https://gallery.verynifty.io/api";
    }

    // in case a bug happens or we upgrade to another smart contract
    function pauseGame(bool _pause) external onlyOperator {
        gameStopped = _pause;
    }

    function changeFatalityPct(uint256 _newpct) external onlyOperator {
        fatalityPct = _newpct;
    }

    // change how much to burn on each buy and how much goes to community.
    function changeBurnPercentage(uint256 percentage) external onlyOperator {
        require(percentage <= 100);
        burnPercentage = burnPercentage;
        emit BurnPercentageChanged(burnPercentage);
    }

    function changeGiveLifePrice(uint256 _newPrice) external onlyOperator {
        giveLifePrice = _newPrice * 10**18;
    }

    function changeMaxDevAllocation(uint256 amount) external onlyOperator {
        maxDevAllocation = amount;
    }

    function itemExists(uint256 itemId) public view returns (bool) {
        if (bytes(itemName[itemId]).length > 0) {
            return true;
        }
    }

    // check that VNFT didn't starve
    function isVnftAlive(uint256 _nftId) public view returns (bool) {
        uint256 _timeUntilStarving = timeUntilStarving[_nftId];
        if (_timeUntilStarving != 0 && _timeUntilStarving >= block.timestamp) {
            return true;
        }
    }

    function getVnftScore(uint256 _nftId) public view returns (uint256) {
        return vnftScore[_nftId];
    }

    function getItemInfo(uint256 _itemId)
        public
        view
        returns (
            string memory _name,
            uint256 _price,
            uint256 _points,
            uint256 _timeExtension
        )
    {
        _name = itemName[_itemId];
        _price = itemPrice[_itemId];
        _timeExtension = itemTimeExtension[_itemId];
        _points = itemPoints[_itemId];
    }

    function getVnftInfo(uint256 _nftId)
        public
        view
        returns (
            uint256 _vNFT,
            bool _isAlive,
            uint256 _score,
            uint256 _level,
            uint256 _expectedReward,
            uint256 _timeUntilStarving,
            uint256 _lastTimeMined,
            uint256 _timeVnftBorn,
            address _owner,
            address _token,
            uint256 _tokenId,
            uint256 _fatalityReward
        )
    {
        _vNFT = _nftId;
        _isAlive = this.isVnftAlive(_nftId);
        _score = this.getVnftScore(_nftId);
        _level = this.level(_nftId);
        _expectedReward = this.getRewards(_nftId);
        _timeUntilStarving = timeUntilStarving[_nftId];
        _lastTimeMined = lastTimeMined[_nftId];
        _timeVnftBorn = timeVnftBorn[_nftId];
        _owner = this.ownerOf(_nftId);
        _token = vnftDetails[_nftId].token;
        _tokenId = vnftDetails[_nftId].id;
        _fatalityReward = getFatalityReward(_nftId);
    }

    function editCurves(
        uint256 _la,
        uint256 _lb,
        uint256 _ra,
        uint256 _rb
    ) external onlyOperator {
        la = _la;
        lb = _lb;
        ra = _ra;
        lb = _rb;
    }

    uint256 la = 2;
    uint256 lb = 2;
    uint256 ra = 6;
    uint256 rb = 7;

    // get the level the vNFT is on to calculate points
    function level(uint256 tokenId) external view returns (uint256) {
        // This is the formula L(x) = 2 * sqrt(x * 2)
        uint256 _score = vnftScore[tokenId].div(100);
        if (_score == 0) {
            return 1;
        }
        uint256 _level = sqrtu(_score.mul(la));
        return (_level.mul(lb));
    }

    // get the level the vNFT is on to calculate the token reward
    function getRewards(uint256 tokenId) external view returns (uint256) {
        // This is the formula to get token rewards R(level)=(level)*6/7+6
        uint256 _level = this.level(tokenId);
        if (_level == 1) {
            return 6 ether;
        }
        _level = _level.mul(1 ether).mul(ra).div(rb);
        return (_level.add(5 ether));
    }

    // edit specific item in case token goes up in value and the price for items gets to expensive for normal users.
    function editItem(
        uint256 _id,
        uint256 _price,
        uint256 _points,
        string calldata _name,
        uint256 _timeExtension
    ) external onlyOperator {
        itemPrice[_id] = _price;
        itemPoints[_id] = _points;
        itemName[_id] = _name;
        itemTimeExtension[_id] = _timeExtension;
    }

    //can mine once every 24 hours per token.
    function claimMiningRewards(uint256 nftId) external notPaused {
        require(isVnftAlive(nftId), "Your vNFT is dead, you can't mine");
        require(
            block.timestamp >= lastTimeMined[nftId].add(1 days) ||
                lastTimeMined[nftId] == 0,
            "Current timestamp is over the limit to claim the tokens"
        );
        require(
            ownerOf(nftId) == msg.sender ||
                careTaker[nftId][ownerOf(nftId)] == msg.sender,
            "You must own the vNFT to claim rewards"
        );

        //reset last start mined so can't remine and cheat
        lastTimeMined[nftId] = block.timestamp;
        uint256 _reward = this.getRewards(nftId);
        muse.mint(msg.sender, _reward);
        emit ClaimedMiningRewards(nftId, msg.sender, _reward);
    }

    // Buy accesory to the VNFT
    function buyAccesory(uint256 nftId, uint256 itemId) external notPaused {
        require(itemExists(itemId), "This item doesn't exist");
        uint256 amount = itemPrice[itemId];
        require(
            ownerOf(nftId) == msg.sender ||
                careTaker[nftId][ownerOf(nftId)] == msg.sender,
            "You must own the vNFT or be a care taker to buy items"
        );
        // require(isVnftAlive(nftId), "Your vNFT is dead");
        uint256 amountToBurn = amount.mul(burnPercentage).div(100);

        // recalculate time until starving
        timeUntilStarving[nftId] = block.timestamp.add(
            itemTimeExtension[itemId]
        );
        if (!isVnftAlive(nftId)) {
            vnftScore[nftId] = itemPoints[itemId];
        } else {
            vnftScore[nftId] = vnftScore[nftId].add(itemPoints[itemId]);
        }
        // burn 90% so they go back to community mining and staking, and send 10% to devs

        if (devAllocation <= maxDevAllocation) {
            devAllocation = devAllocation.add(amount.sub(amountToBurn));
            muse.transferFrom(msg.sender, address(this), amount);
            // burn 90% of token, 10% stay for dev and community fund
            muse.burn(amountToBurn);
        } else {
            muse.burnFrom(msg.sender, amount);
        }
        emit VnftConsumed(nftId, msg.sender, itemId);
    }

    function setBaseURI(string memory baseURI_) public onlyOperator {
        _setBaseURI(baseURI_);
    }

    function mint(address player) public override onlyMinter {
        //pet minted has 3 days until it starves at first
        timeUntilStarving[_tokenIds.current()] = block.timestamp.add(3 days);
        timeVnftBorn[_tokenIds.current()] = block.timestamp;

        vnftDetails[_tokenIds.current()] = VNFTObj(
            address(this),
            _tokenIds.current(),
            721
        );
        super._mint(player, _tokenIds.current());
        _tokenIds.increment();
        emit VnftMinted(msg.sender);
    }

    // kill starverd NFT and get fatalityPct of his points.
    function fatality(uint256 _deadId, uint256 _tokenId) external notPaused {
        require(
            !isVnftAlive(_deadId),
            "The vNFT has to be starved to claim his points"
        );
        vnftScore[_tokenId] = vnftScore[_tokenId].add(
            (vnftScore[_deadId].mul(fatalityPct).div(100))
        );
        vnftScore[_deadId] = 0;
        delete vnftDetails[_deadId];
        _burn(_deadId);
        emit VnftFatalized(_deadId, msg.sender);
    }

    // Check how much score you'll get by fatality someone.
    function getFatalityReward(uint256 _deadId) public view returns (uint256) {
        if (isVnftAlive(_deadId)) {
            return 0;
        } else {
            return (vnftScore[_deadId].mul(60).div(100));
        }
    }

    // add items/accessories
    function createItem(
        string calldata name,
        uint256 price,
        uint256 points,
        uint256 timeExtension
    ) external onlyOperator returns (bool) {
        _itemIds.increment();
        uint256 newItemId = _itemIds.current();
        itemName[newItemId] = name;
        itemPrice[newItemId] = price * 10**18;
        itemPoints[newItemId] = points;
        itemTimeExtension[newItemId] = timeExtension;
        emit ItemCreated(newItemId, name, price, points);
    }

    //  *****************************
    //  LOGIC FOR EXTERNAL NFTS
    //  ****************************
    // support an external nft to mine rewards and play
    function addNft(address _nftToken, uint256 _type) public onlyOperator {
        supportedNfts.push(
            NFTInfo({token: _nftToken, active: true, standard: _type})
        );
    }

    function supportedNftLength() external view returns (uint256) {
        return supportedNfts.length;
    }

    function updateSupportedNFT(
        uint256 index,
        bool _active,
        address _address
    ) public onlyOperator {
        supportedNfts[index].active = _active;
        supportedNfts[index].token = _address;
    }

    // aka WRAP: lets give life to your erc721 token and make it fun to mint $muse!
    function giveLife(
        uint256 index,
        uint256 _id,
        uint256 nftType
    ) external notPaused {
        uint256 amountToBurn = giveLifePrice.mul(burnPercentage).div(100);

        if (devAllocation <= maxDevAllocation) {
            devAllocation = devAllocation.add(giveLifePrice.sub(amountToBurn));
            muse.transferFrom(msg.sender, address(this), giveLifePrice);
            // burn 90% of token, 10% stay for dev and community fund
            muse.burn(amountToBurn);
        } else {
            muse.burnFrom(msg.sender, giveLifePrice);
        }

        if (nftType == 721) {
            IERC721(supportedNfts[index].token).transferFrom(
                msg.sender,
                address(this),
                _id
            );
        } else if (nftType == 1155) {
            IERC1155(supportedNfts[index].token).safeTransferFrom(
                msg.sender,
                address(this),
                _id,
                1, //the amount of tokens to transfer which always be 1
                "0x0"
            );
        }

        // mint a vNFT
        vnftDetails[_tokenIds.current()] = VNFTObj(
            supportedNfts[index].token,
            _id,
            nftType
        );

        timeUntilStarving[_tokenIds.current()] = block.timestamp.add(3 days);
        timeVnftBorn[_tokenIds.current()] = block.timestamp;

        super._mint(msg.sender, _tokenIds.current());
        _tokenIds.increment();
        emit LifeGiven(supportedNfts[index].token, _id);
    }

    // unwrap your vNFT if it is not dead, and get back your original NFT
    function unwrap(uint256 _vnftId) external {
        require(isVnftAlive(_vnftId), "Your vNFT is dead, you can't unwrap it");
        transferFrom(msg.sender, address(this), _vnftId);
        VNFTObj memory details = vnftDetails[_vnftId];
        timeUntilStarving[_vnftId] = 1;
        vnftScore[_vnftId] = 0;
        emit Unwrapped(_vnftId);
        _withdraw(details.id, details.token, msg.sender, details.standard);
    }

    // withdraw dead wrapped NFTs or send them to the burn address.
    function withdraw(
        uint256 _id,
        address _contractAddr,
        address _to,
        uint256 _type
    ) external onlyOperator {
        _withdraw(_id, _contractAddr, _to, _type);
    }

    function _withdraw(
        uint256 _id,
        address _contractAddr,
        address _to,
        uint256 _type
    ) internal {
        if (_type == 1155) {
            IERC1155(_contractAddr).safeTransferFrom(
                address(this),
                _to,
                _id,
                1,
                ""
            );
        } else if (_type == 721) {
            IERC721(_contractAddr).transferFrom(address(this), _to, _id);
        }
    }

    // add care taker so in the future if vNFTs are sent to tokenizing platforms like niftex we can whitelist and the previous owner could still mine and do interesting stuff.
    function addCareTaker(uint256 _tokenId, address _careTaker) external {
        require(
            hasRole(OPERATOR_ROLE, _msgSender()) ||
                ownerOf(_tokenId) == msg.sender,
            "Roles: caller does not have the OPERATOR role"
        );
        careTaker[_tokenId][msg.sender] = _careTaker;
        emit CareTakerAdded(_tokenId, _careTaker);
    }

    function clearCareTaker(uint256 _tokenId) external {
        require(
            hasRole(OPERATOR_ROLE, _msgSender()) ||
                ownerOf(_tokenId) == msg.sender,
            "Roles: caller does not have the OPERATOR role"
        );
        delete careTaker[_tokenId][msg.sender];
        emit CareTakerRemoved(_tokenId);
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }
}