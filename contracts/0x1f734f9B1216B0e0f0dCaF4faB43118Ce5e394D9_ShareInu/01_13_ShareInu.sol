// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interface/IMasterShareInu.sol";
import "./interface/IUniswapRouter.sol";
import "./interface/IUniswapFactory.sol";

contract ShareInu is Ownable, ERC20("ShareNow Inu", "SHAREINU"), ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(bytes32 => address) public codeMap;
    mapping(address => bool) public swapPools;
    mapping(address => UserInfo) public userInfo;

    mapping(address => bool) private _isExcludedFromFee;

    address public masterShareInu;
    address public marketingAddress;
    address public immutable weth;
    address public constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    bool private inSwap;

    uint private rewardAmt;
    uint public buyTax = 600;
    uint public sellTax = 600;
    uint public maxWallet = 1e23;
    uint public maxTransfer = 1e23;

    struct UserInfo {
        uint amount;
        uint parents;
        uint children;
        address parent;
        bytes32 referCode;
    }

    event SetTax(uint, uint);
    event SetMax(uint, uint);
    event Claim(address indexed, uint);
    event UserRegistered(address indexed user, address indexed parent, bytes32);

    /**
     * @notice Constructor
     * @param _marketing  Address of marketing wallet
     */
    constructor(
        address _marketing
    ) payable {
        marketingAddress = _marketing;

        // init _isExcludedFromFee
        _isExcludedFromFee[router] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_marketing] = true;
        _isExcludedFromFee[address(this)] = true;

        // mint tokens for liquidity
        _mint(owner(), 1e25);

        // create uniswapv2 pair and add to swapPools
        weth = IUniswapRouter(router).WETH();
        swapPools[IUniswapFactory(factory).createPair(weth, address(this))] = true;
    }

    /**
     * @notice Fucntion for add liquidity
     * @param _amount  Amount of token to add
     */
    function addLiquidity(uint _amount) external payable {
        if(msg.value != 0 && _amount != 0) {
            super._transfer(msg.sender, address(this), _amount);
            _approve(address(this), router, _amount);
            IUniswapRouter(router).addLiquidityETH {value: msg.value} (
                address(this),
                _amount,
                0,
                0,
                msg.sender,
                block.timestamp + 2 hours
            );
        }
    }

    /**
     * @notice Set masterShareInu
     * @param _masterShareInu  Address of masterShareInu
     */
    function setmasterShareInu(address _masterShareInu) external onlyOwner {
        masterShareInu = _masterShareInu;
        _isExcludedFromFee[masterShareInu] = true;
    }

    /**
     * @notice Update swap pools
     * @param _routers  Array of router address
     * @param _flag  Bool if router or not
     */
    function setPools(
        address[] calldata _routers, 
        bool _flag
    ) external onlyOwner {
        for(uint8 i; i < _routers.length; ++i) {
            swapPools[_routers[i]] = _flag;
        }
    }

    /**
     * @notice Update _isExcludedFromFee
     * @param _wallets  Array of router address
     * @param _flag  Bool if router or not
     */
    function setExcludedFee(
        address[] calldata _wallets, 
        bool _flag
    ) external onlyOwner {
        for(uint8 i; i < _wallets.length; ++i) {
            _isExcludedFromFee[_wallets[i]] = _flag;
        }
    }

    /**
     * @notice Update buy/sell tax
     * @param _buyTax  Value of new tax
     * @param _sellTax  Value of new tax
     */
    function setTax(
        uint _buyTax, 
        uint _sellTax
    ) external onlyOwner {
        buyTax = _buyTax;
        sellTax = _sellTax;

        emit SetTax(buyTax, sellTax);
    }

    /**
     * @notice Update max transfer/wallet
     * @param _maxWallet  Percent of max wallet
     * @param _maxTransfer  Percent of max transfer
     */
    function setMax(
        uint _maxWallet,
        uint _maxTransfer
    ) external onlyOwner {
        maxWallet = _maxWallet;
        maxTransfer = _maxTransfer;

        emit SetMax(maxWallet, maxTransfer);
    }

    /**
     * @notice Update marketing address
     * @param _marketing  Address of marketing address
     */
    function setMarketing(
        address _marketing
    ) external onlyOwner {
        marketingAddress = _marketing;
    }

    /**
     * @notice Set refer code to user
     * @param _user  Address of user
     */
    function _setCode(address _user) private {
        bytes32 code;

        do {
            uint rand = uint256(
                keccak256(abi.encode(block.difficulty, block.timestamp, _user))
            );

            unchecked {
                rand -= (rand / 1e10) * 1e10;
            }

            code = bytes32(rand);
        } while(codeMap[code] != address(0));

        codeMap[code] = _user;
        userInfo[_user].referCode = code;

        emit UserRegistered(_user, address(0), code);
    }

    /**
     * @notice Distribute tokens to his parents
     * @param _user  Address of user
     * @param _balance  Amount to distribute
     */
    function _distributeToParent(
        address _user,
        uint _balance
    ) private returns(uint _dist) {
        UserInfo storage info = userInfo[_user];
        if(info.parents != 0 && _balance != 0) {
            address parent = info.parent;
            unchecked {
                _balance = _balance / info.parents;
                for(uint i; i < info.parents; ++i) {
                    userInfo[parent].amount = userInfo[parent].amount + _balance;
                    parent = userInfo[parent].parent;
                }

                _dist = _balance * info.parents;
            }
        }
    }

    /**
     * @notice Swap token to ETH
     * @param _amountIn  Amount of token
     */
    function _swapToken(
        uint _amountIn
    ) private returns(uint _amountOut) {
        _amountOut = address(this).balance;
        _approve(address(this), router, _amountIn);

        address[] memory paths = new address[](2);
        paths[0] = address(this);
        paths[1] = weth;

        IUniswapRouter(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amountIn,
            0,
            paths,
            address(this),
            block.timestamp + 2 hours
        );

        unchecked {
            _amountOut = address(this).balance - _amountOut;
        }
    }

    /**
     * @notice Swap token and send to marketing
     */
    function _distributeReward() private {
        if(rewardAmt > 0) {
            uint ethAmt = _swapToken(rewardAmt);

            (bool success, ) = payable(marketingAddress).call{value: ethAmt}("");
            require(success, "Failed to send marketing wallet");

            rewardAmt = 0;
        }
    }

    function pendingReward(address user) external view returns(uint reward) {
        UserInfo memory userItem = userInfo[user];
        if(userItem.amount > 0) {
            address[] memory paths = new address[](2);
            paths[0] = address(this);
            paths[1] = weth;

            reward = IUniswapRouter(router).getAmountsOut(
                userItem.amount,
                paths
            )[1];
        }
    }

    /**
     * @notice Purchase token
     * @param _parCode  Referal Code of parent
     * @param _userCode  Referal Code of user
     * @param _amount  Amount of token for purchase
     * @param _token  Address of purchasing token
     */
    function purchase(
        bytes32 _parCode,
        bytes32 _userCode,
        uint _amount,
        address _token
    ) external payable {
        address user = msg.sender;

        // set code if new user
        if(userInfo[user].referCode == 0) {
            require(_userCode != 0, "Invalid code");
            // check parent code is empty or registered already
            require(_parCode == 0 || codeMap[_parCode] != address(0), "Invalid code");

            codeMap[_userCode] = user;
            bool zeroParent = _parCode == 0;
            address parentAddr = zeroParent ? address(0) : codeMap[_parCode];
            userInfo[user] = UserInfo(
                0,
                zeroParent ? 0 : userInfo[codeMap[_parCode]].parents + 1,
                0,
                parentAddr,
                _userCode
            );

            if(!zeroParent) ++userInfo[parentAddr].children;

            emit UserRegistered(user, parentAddr, _userCode);
        }

        // swap on router
        if(msg.value == 0) { // if erc20
            IERC20(_token).safeTransferFrom(user, address(this), _amount);
            IERC20(_token).approve(router, _amount);

            address[] memory paths = new address[](3);
            paths[0] = _token;
            paths[1] = weth;
            paths[2] = address(this);

            IUniswapRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount,
                0,
                paths,
                msg.sender,
                block.timestamp + 2 hours
            );
        } else { // if ETH
            address[] memory paths = new address[](2);
            paths[0] = weth;
            paths[1] = address(this);

            IUniswapRouter(router).swapExactETHForTokensSupportingFeeOnTransferTokens
            {value: msg.value} (
                0,
                paths,
                msg.sender,
                block.timestamp + 2 hours
            );
        }

        _distributeReward();
    }

    /**
     * @notice Claim available token amount
     */
    function claim() external nonReentrant {
        address user = msg.sender;

        UserInfo storage userItem = userInfo[user];
        if(userItem.amount != 0) {
            uint ethAmt = _swapToken(userItem.amount);

            userItem.amount = 0;

            (bool success, ) = payable(user).call{value: ethAmt}(
                ""
            );
            require(success, "Failed to claim");

            emit Claim(user, ethAmt);
        }
    }

    /**
     * @notice Override transfer
     * @param _from  Address of sender
     * @param _to  Address of receiver
     * @param _amount  Amount of token
     */
    function _transfer(
        address _from,
        address _to,
        uint _amount
    ) internal override {
        if (!_isExcludedFromFee[_from] && !_isExcludedFromFee[_to]) {
            // check for max transfer amount
            require(_amount <= maxTransfer, "Over max transfer");

            // check for max balance
            require(swapPools[_to] || balanceOf(_to) + _amount <= maxWallet, "Over max balance");

            if(swapPools[_from]) { // if user buys token
                if(userInfo[_to].referCode == 0) { // if buyer has no code
                    _setCode(_to);
                }

                unchecked {
                    uint taxAmount = _amount * buyTax / 1e4;
                    _amount = _amount - taxAmount;

                    super._transfer(_from, address(this), taxAmount);

                    uint distAmt = _distributeToParent(_to, taxAmount / 2);
                    rewardAmt += taxAmount - distAmt;
                }
            } else if(swapPools[_to]) { // is user sells token
                unchecked {
                    uint taxAmount = _amount * sellTax / 1e4;
                    _amount = _amount - taxAmount;

                    super._transfer(_from, address(this), taxAmount);

                    uint ethAmt = _swapToken(taxAmount);
                    uint distAmt = ethAmt / 2;
                    (bool success, ) = payable(masterShareInu).call{value: ethAmt / 2}("");
                    require(success, "Failed to send staking contract");
                    IMasterShareInu(masterShareInu).updateInfo(distAmt);

                    (success, ) = payable(marketingAddress).call{value: ethAmt - distAmt}("");
                    require(success, "Failed to send marketing wallet");
                }
            } else {
                _distributeReward();
            }

            if(!swapPools[_to] && userInfo[_to].referCode == 0) { // if receiver has no code
                _setCode(_to);
            }
        }
            
        super._transfer(_from, _to, _amount);
    }

    receive() external payable {}
}