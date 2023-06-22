// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityLockerWithTokenBurn {
    function withdrawTradingFees(uint256 tokenId) external;
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

interface IBurner {
    function leaderboard(uint256 _topIndex) external view returns (address);
    function gameOver() external view returns (bool);
}

interface ILocker {
    function changeOwner(address newOwner) external;
    function owner() external view returns (address);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface OperatorFilterRegistry {
    function isOperatorAllowed(address, address) external view returns (bool);
    function registerAndSubscribe(address, address) external;
}

contract MrFrog is ERC721A {

    error OperatorNotAllowed(address operator);

    OperatorFilterRegistry constant public OPERATOR_FILTER_REGISTRY = OperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    bool public operatorFilterEnabled;

    // Token stuff
    string baseURI;
    uint256 constant public maxSupply = 3700;
    uint256 constant public mintPrice = 100e18; // 100 $MRF
    uint256 constant public maxMint = 50;
    uint256 constant presetCount = 80;
    uint256 constant ultraRareCount = 10;

    uint constant poolA = 511310;
    uint constant poolB = 511313;

    uint128 public offsetBlock;
    uint128 public offset;

    // External contracts
    address immutable mrF;
    address immutable token;
    IBurner immutable burner;
    address immutable locker;
    address immutable weth;

    // Rarity
    mapping(uint256 => bool) public isRare;
    bool public locked;

    // Distribution variables
    uint256 public previousEth;
    uint256 public receivedEth;
    mapping(uint256 => uint) public claimedEth;

    struct rewardToken {
        uint256 received;
        uint256 balance;
        mapping(uint256 => uint) claimedTokens;
    }

    mapping(address => rewardToken) rewardTokens;

    modifier onlyOwner() {
        require(msg.sender == mrF, "Not owner");
        _;
    }

    modifier onlyAllowedOperator(address _from) {
        if (operatorFilterEnabled && address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (_from == msg.sender) {
                _;
                return;
            }
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address _operator) {
        if (operatorFilterEnabled && address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), _operator)) {
                revert OperatorNotAllowed(_operator);
            }
        }
        _;
    }

    constructor(string memory _uri, address _mrF, address _token, IBurner _burner, address _locker, address _weth) ERC721A("Mr Frog", "MRFROG")  {
        operatorFilterEnabled = true;
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
        }

        baseURI = _uri;
        mrF = _mrF;
        token = _token;
        burner = _burner;
        locker = _locker;
        weth = _weth;

        // Ultra rares for claiming
        _mint(address(this), ultraRareCount);
        // Preset tokens will be airdropped
        _mint(_mrF, presetCount - ultraRareCount);
    }

    // Owner functions

    function emergencyOwnershipTransfer() external onlyOwner {
        require(!locked, "Locked");
        address this_ = address(this);                  // shorthand
        if (ILocker(locker).owner() == this_)
            ILocker(locker).changeOwner(mrF);         // transfer lp ownership back to Mr F
    }

    function setOperatorFilterEnabled(bool _enabled) external onlyOwner {
        operatorFilterEnabled = _enabled;
    }

    function bulkRare(uint256[] calldata _ids) external onlyOwner {
        require(!locked, "Locked");
        for (uint256 i = 0; i < _ids.length; i++) {
            isRare[_ids[i]] = true;
        }
    }

    function setRare(uint256 _id, bool _state) external onlyOwner {
        require(!locked, "Locked");
        isRare[_id] = _state;
    }

    function lock() external onlyOwner {
        locked = true;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function initOffset() external onlyOwner {
        require(super.totalSupply() == maxSupply, "Sale not over");
        offsetBlock = uint128(block.number) + 1;
    }

    function finalizeOffset() external {
        require(offset == 0, "Starting index is already set");
        require(offsetBlock != 0, "Starting index block must be set");
        require(block.number - offsetBlock < 255, "Must re-init");

        uint128 _offset = uint128(uint256(blockhash(offsetBlock)) % (maxSupply - presetCount));

        // Prevent default sequence
        if (_offset == 0) {
            _offset = 1;
        }

        offset = _offset;
    }

    // Minting logic

    function claim(uint256 _index) external {
        require(_index < 10, "Invalid index");
        require(burner.leaderboard(_index) == msg.sender, "Address does not match");
        require(burner.gameOver(), "Game not over");

        this.transferFrom(address(this), msg.sender, _index + 1);
    }

    function mint(uint256 _num) external {
        require(_num != 0, "Invalid amount");
        require(_num <= maxMint, "Exceeds maximum");
        require(IERC20(token).allowance(msg.sender, address(this)) >= mintPrice * _num, "Insufficient allowance");
        require(IERC20(token).transferFrom(msg.sender, address(this), mintPrice * _num), "Token transfer failed");

        IERC20Burnable burnableToken = IERC20Burnable(token);

        uint256 tokenId = super.totalSupply();

        require(tokenId <= maxSupply, "Mint complete");

        if (tokenId + _num > maxSupply) {
            uint256 remaining = maxSupply - tokenId;
            uint256 excess = _num - remaining;

            // Mint the frogs
            _mint(msg.sender, remaining);
            // Refund excess
            IERC20(token).transfer(msg.sender, excess * mintPrice);
            // Burn the MRF
            burnableToken.burn(mintPrice * remaining);
        } else {
            // Mint the frogs
            _mint(msg.sender, _num);
            // Burn the MRF
            burnableToken.burn(mintPrice * _num);
        }
    }

    function receiveApproval(address _receiveFrom, uint256 _amount, address, bytes memory) external {
        require(msg.sender == token, "Invalid token");
        require(IERC20(token).transferFrom(_receiveFrom, address(this), _amount), "Token transfer failed");
        uint256 num = _amount / mintPrice;
        require(num != 0, "Invalid amount");
        require(num <= maxMint, "Exceeds maximum");
        uint256 excess = _amount - num * mintPrice;

        uint256 tokenId = super.totalSupply();

        require(tokenId <= maxSupply, "Mint complete");

        if (tokenId + num > maxSupply) {
            uint256 remaining = maxSupply - tokenId;
            excess += (num - remaining) * mintPrice;

            // Mint the frogs
            _mint(_receiveFrom, remaining);
        } else {
            _mint(_receiveFrom, num);
        }

        // Burn the MRF
        IERC20Burnable(token).burn(_amount - excess);
        if (excess > 0) {
            IERC20(token).transfer(_receiveFrom, excess);
        }
    }

    // Distribution stuff

    fallback() external payable {}

    receive() external payable {}

    function withdrawLocker() private {
        bool ignoreMe;
        // attempt to pull liquidity fees from poolA
        (ignoreMe,) = address(locker).call(abi.encodeWithSignature("withdrawTradingFees(uint256)", poolA));
        // attempt to pull liquidity fees from poolB
        (ignoreMe,) = address(locker).call(abi.encodeWithSignature("withdrawTradingFees(uint256)", poolB));
    }

    function withdrawEth(uint32[] calldata _ids) external {
        require(locked, "Not locked");

        // Pull trading fees
        withdrawLocker();

        // Convert any owned WETH to ETH
        IERC20 WETH_ = IERC20(weth);
        uint wethBal = WETH_.balanceOf(address(this));
        if (wethBal > 0) {
            IWETH(weth).withdraw(wethBal);
        }

        uint256 totalRewards;
        uint256 currentBalance = address(this).balance;
        uint256 increase = currentBalance - previousEth;
        uint256 totalEth = receivedEth + increase;

        if (increase > 0) {
            receivedEth += increase;
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            require(ownerOf(_ids[i]) == msg.sender, "Must own the token");
            uint256 frogEth = 0;

            // Adjust totalRewards based on token ID or rarity
            if (_ids[i] >= 1 && _ids[i] <= ultraRareCount) {
                frogEth = (totalEth * 3 / 100) - claimedEth[_ids[i]];
                claimedEth[_ids[i]] += frogEth;
            } else if ((_ids[i] >= ultraRareCount + 1 && _ids[i] <= presetCount) || isRare[_ids[i]]) {
                // 0.7777%
                frogEth = (totalEth * 7 / 900) - claimedEth[_ids[i]];
                claimedEth[_ids[i]] += frogEth;
            }

            totalRewards += frogEth;
        }

        // Update Eth balance
        previousEth = currentBalance - totalRewards;

        // Send the rewards
        (bool success, ) = payable(msg.sender).call{value: totalRewards}("");
        require(success, "Failed to transfer");
    }

    function checkEth(uint32[] calldata _ids) external view returns (uint256) {
        return checkEthWithFees(_ids, 0);
    }

    function checkEthWithFees(uint32[] calldata _ids, uint256 _fees) public view returns (uint256) {
        uint256 totalRewards;
        uint256 currentBalance = address(this).balance;
        uint256 increase = currentBalance - previousEth;
        uint256 totalEth = receivedEth + increase + _fees;

        // Count any WETH in total
        totalEth += IERC20(weth).balanceOf(address(this));

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 frogEth = 0;

            // Adjust totalRewards based on token ID or rarity
            if (_ids[i] >= 1 && _ids[i] <= ultraRareCount) {
                frogEth = (totalEth * 3 / 100) - claimedEth[_ids[i]];
            } else if ((_ids[i] >= ultraRareCount + 1 && _ids[i] <= presetCount) || isRare[_ids[i]]) {
                // 0.7777%
                frogEth = (totalEth * 7 / 900) - claimedEth[_ids[i]];
            }

            totalRewards += frogEth;
        }

        return totalRewards;
    }

    function withdrawTokens(address _token, uint32[] calldata _ids) external {
        require(locked, "Not locked");
        require(_token != weth, "Cannot withdraw WETH");

        uint256 totalRewards;

        uint256 currentBalance = IERC20(_token).balanceOf(address(this));
        uint256 previousBalance = rewardTokens[_token].balance;
        uint256 increase = currentBalance - previousBalance;
        uint256 totalTokens = rewardTokens[_token].received + increase;

        if (increase > 0) {
            rewardTokens[_token].received += increase;
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            require(ownerOf(_ids[i]) == msg.sender, "Must own the token");
            uint256 frogTokens = 0;

            // Adjust totalRewards based on token ID or rarity
            if (_ids[i] >= 1 && _ids[i] <= ultraRareCount) {
                frogTokens = (totalTokens * 3 / 100) - rewardTokens[_token].claimedTokens[_ids[i]];
                rewardTokens[_token].claimedTokens[_ids[i]] += frogTokens;
            } else if ((_ids[i] >= ultraRareCount + 1 && _ids[i] <= presetCount) || isRare[_ids[i]]) {
                // 0.7777%
                frogTokens = (totalTokens * 7 / 900) - rewardTokens[_token].claimedTokens[_ids[i]];
                rewardTokens[_token].claimedTokens[_ids[i]] += frogTokens;
            }

            totalRewards += frogTokens;
        }

        // Update token balance
        rewardTokens[_token].balance = currentBalance - totalRewards;

        IERC20(_token).transfer(msg.sender, totalRewards);
    }

    function checkTokens(address _token, uint32[] calldata _ids) external view returns (uint256) {
        uint256 totalRewards;

        uint256 balance = IERC20(_token).balanceOf(address(this));
        uint256 increase = balance - rewardTokens[_token].balance;
        uint256 totalTokens = rewardTokens[_token].received + increase;

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 frogTokens = 0;

            // Adjust totalRewards based on token ID or rarity
            if (_ids[i] >= 1 && _ids[i] <= ultraRareCount) {
                frogTokens = (totalTokens * 3 / 100) - rewardTokens[_token].claimedTokens[_ids[i]];
            } else if ((_ids[i] >= ultraRareCount + 1 && _ids[i] <= presetCount) || isRare[_ids[i]]) {
                // 0.7777%
                frogTokens = (totalTokens * 7 / 900) - rewardTokens[_token].claimedTokens[_ids[i]];
            }

            totalRewards += frogTokens;
        }

        return totalRewards;
    }

    function allInfoFor(address _user) external view returns (uint256 supply, uint256 ethRewards, uint256 mrfRewards, uint256 userBalance, uint256 userAllowance) {
        address _this = address(this);
        IERC20 _token = IERC20(token);
        return (super.totalSupply(), _this.balance, _token.balanceOf(_this), _token.balanceOf(_user), _token.allowance(_user, _this));
    }

    // ERC712 things

    function bulkSafeTransferFrom(
        address _from,
        address[] calldata _to,
        uint256[] calldata _tokenId
    ) external {
        require(
            _to.length == _tokenId.length,
            "Input arrays length mismatch"
        );

        for (uint256 i = 0; i < _to.length; i++) {
            safeTransferFrom(_from, _to[i], _tokenId[i]);
        }
    }

    function setApprovalForAll(address _operator, bool _approved) public override onlyAllowedOperatorApproval(_operator) {
        super.setApprovalForAll(_operator, _approved);
    }

    function approve(address _operator, uint256 _tokenId) public payable override onlyAllowedOperatorApproval(_operator) {
        super.approve(_operator, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable override onlyAllowedOperator(_from) {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        if (bytes(baseURI).length == 0) {
            return '';
        }

        if (_tokenId >= 1 && _tokenId <= presetCount) {
            return string(abi.encodePacked(baseURI, _toString(_tokenId)));
        }

        if (offset == 0) {
            // Token 0 is unrevealed metadata
            return string(abi.encodePacked(baseURI, _toString(0)));
        }

        return string(abi.encodePacked(baseURI, _toString(((_tokenId + offset - 1) % (maxSupply - presetCount)) + 1 + presetCount)));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        // Token ID should start at 1, obviously
        return 1;
    }
}