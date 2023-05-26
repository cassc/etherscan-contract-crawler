// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDAMA.sol";
import "./INewKinko.sol";

contract NewKinko is INewKinko, IERC721Receiver, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    address DAMA;

    EnumerableSet.AddressSet erc721s;
    mapping(address => uint256) public perDays;

    mapping(address => mapping(address => EnumerableSet.UintSet))
        private _deposits;
    mapping(address => mapping(address => uint256)) public depositBlockTimes;

    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public totalSupply;

    mapping(address => uint256) public joined;

    modifier onlyRegistered(address erc721) {
        require(erc721s.contains(erc721), "unregistered ERC721");
        _;
    }

    constructor() {
        startTimestamp = 1638316800;
        endTimestamp = 1764547200;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setDama(address dama) public onlyOwner {
        DAMA = dama;
    }

    function addERC721(address erc721, uint256 perDay) public onlyOwner {
        require(
            IERC721(erc721).supportsInterface(0x80ac58cd),
            "Only ERC721 by ERC165"
        );
        require(!erc721s.contains(erc721), "Already Registry ERC721");
        erc721s.add(erc721);
        perDays[erc721] = perDay;
    }

    function modifyERC721(address erc721, uint256 perDay)
        public
        onlyOwner
        onlyRegistered(erc721)
    {
        perDays[erc721] = perDay;
    }

    function removeERC721(address erc721)
        public
        onlyOwner
        onlyRegistered(erc721)
    {
        erc721s.remove(erc721);
        perDays[erc721] = 0;
    }

    function modifyEndTimestamp(uint256 timestamp) public onlyOwner {
        require(
            endTimestamp < timestamp,
            "timestamp must be greater than endTimestamp."
        );
        endTimestamp = timestamp;
    }

    function joinOf(address erc721, address account)
        public
        view
        override
        onlyRegistered(erc721)
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[erc721][account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function batchClaimRewards() public override nonReentrant {
        for (uint256 i = 0; i < erc721s.length(); i++) {
            address erc721 = erc721s.at(i);
            _claimRewards(erc721);
        }
    }

    function claimRewards(address erc721) public override nonReentrant {
        _claimRewards(erc721);
    }

    function calcReward(address erc721, address account)
        public
        view
        override
        returns (uint256)
    {
        return
            perDays[erc721]
                .mul(_deposits[erc721][account].length())
                .mul(
                    Math.min(block.timestamp, endTimestamp) -
                        (
                            depositBlockTimes[erc721][account] == 0
                                ? block.timestamp
                                : depositBlockTimes[erc721][account]
                        )
                )
                .div(1 days);
    }

    function calcRewardAll(address account)
        public
        view
        override
        returns (uint256)
    {
        uint256 reward = 0;
        for (uint256 i = 0; i < erc721s.length(); i++) {
            address erc721 = erc721s.at(i);
            reward += calcReward(erc721, account);
        }
        return reward;
    }

    function _claimRewards(address erc721) internal onlyRegistered(erc721) {
        uint256 reward = calcReward(erc721, msg.sender);
        if (reward > 0) {
            IDAMA(DAMA).mint(msg.sender, reward);
        }
        depositBlockTimes[erc721][msg.sender] = block.timestamp;
        totalSupply = totalSupply + reward;
    }

    function join(address erc721, uint256[] calldata tokenIds)
        external
        override
        nonReentrant
        onlyRegistered(erc721)
    {
        require(block.timestamp > startTimestamp, "Can't join yet.");
        _claimRewards(erc721);
        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(erc721).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            _deposits[erc721][msg.sender].add(tokenIds[i]);
            joined[erc721] = joined[erc721] + 1;
        }
    }

    function batchJoin(
        address[] calldata _erc721s,
        uint256[][] calldata tokenIds
    ) external nonReentrant {
        require(
            _erc721s.length == tokenIds.length,
            "Not equals ERC721s length and tokenIds length"
        );
        for (uint256 i; i < _erc721s.length; i++) {
            require(erc721s.contains(_erc721s[i]), "unregistered ERC721");
            _claimRewards(_erc721s[i]);
            for (uint256 j; j < tokenIds[i].length; j++) {
                IERC721(_erc721s[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    tokenIds[i][j]
                );
                _deposits[_erc721s[i]][msg.sender].add(tokenIds[i][j]);
                joined[_erc721s[i]] = joined[_erc721s[i]] + 1;
            }
        }
    }

    function leave(address erc721, uint256[] calldata tokenIds)
        external
        override
        nonReentrant
        onlyRegistered(erc721)
    {
        _claimRewards(erc721);
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[erc721][msg.sender].contains(tokenIds[i]),
                "Token Not joined"
            );

            _deposits[erc721][msg.sender].remove(tokenIds[i]);
            joined[erc721] = joined[erc721] - 1;
            IERC721(erc721).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
        }
    }

    function batchLeave(
        address[] calldata _erc721s,
        uint256[][] calldata tokenIds
    ) external nonReentrant {
        require(
            _erc721s.length == tokenIds.length,
            "Not equals ERC721s length and tokenIds length"
        );

        for (uint256 i; i < _erc721s.length; i++) {
            require(erc721s.contains(_erc721s[i]), "unregistered ERC721");
            _claimRewards(_erc721s[i]);
            for (uint256 j; j < tokenIds[i].length; j++) {
                require(
                    _deposits[_erc721s[i]][msg.sender].contains(tokenIds[i][j]),
                    "Token Not joined"
                );
                _deposits[_erc721s[i]][msg.sender].remove(tokenIds[i][j]);
                joined[_erc721s[i]] = joined[_erc721s[i]] - 1;
                IERC721(_erc721s[i]).safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenIds[i][j]
                );
            }
        }
    }

    function ownerOf(
        address erc721,
        address account,
        uint256 tokenId
    ) external view override returns (bool) {
        return _deposits[erc721][account].contains(tokenId);
    }
}