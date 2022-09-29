// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    function safeTransferBNB(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IBEP165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IBEP165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBEP165).interfaceId;
    }
}

interface IBEP721 is IBEP165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IBEP721Metadata is IBEP721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IRouter {
    function swapExactBNBForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
        
        function addLiquidityBNB(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountBNB, uint liquidity);
    function swapExactTokensForBNB(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function removeLiquidityBNB(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountBNB);

}

interface IPancakeRouter {
    function WETH() external pure returns (address);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface ILpStaking {
    function stakeNonces (address) external view returns (uint256);
    function stake(uint256 amount) external;
    function stakeFor(uint256 amount, address user) external;
    function getCurrentLPPrice() external view returns (uint);
    function getReward() external;
    function withdraw(uint256 nonce) external;
    function rewardDuration() external returns (uint256);
}

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external;
    function withdraw(uint) external;
    function approve(address spender, uint value) external returns (bool);
}

interface ILending {
    function mintWithBnb(address receiver) external payable returns (uint256 mintAmount);
    function tokenPrice() external view returns (uint256);
    function burnToBnb(address receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);
}

contract SmartLPStorage is Initializable, ERC165, ContextUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {    
    IWBNB public WBNB;
    IERC20Upgradeable public purchaseToken;
    IRouter public swapRouter;
    ILpStaking public lpStakingBnbNbu;
    ILpStaking public lpStakingBnbGnbu;
    ILending public lendingContract;
    IERC20Upgradeable public nbuToken;
    IERC20Upgradeable public gnbuToken;

    uint public tokenCount;
    uint public minPurchaseAmountToken;
    uint public rewardDuration;
    uint public lockTime;
    
    struct UserSupply { 
      address ProvidedToken;
      uint ProvidedAmount;
      uint NbuBnbLpAmount;
      uint GnbuBnbLpAmount;
      uint NbuBnbStakeNonce;
      uint GnbuBnbStakeNonce;
      uint LendedBNBAmount;
      uint LendedITokenAmount;
      uint SupplyTime;
      uint TokenId;
      bool IsActive;
    }
    
    mapping(uint => uint[]) internal _userRewards;
    mapping(uint => uint256) internal _balancesRewardEquivalentBnbNbu;
    mapping(uint => uint256) internal _balancesRewardEquivalentBnbGnbu;
    mapping(uint => UserSupply) public tikSupplies;
    mapping(uint => uint256) public weightedStakeDate;

    string internal _name;
    string internal _symbol;
    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    mapping(address => uint[]) internal _userTokens;
    IPancakeRouter public pancakeRouter;

    event BuySmartLP(address indexed user, uint indexed tokenId, address providedToken, uint providedBnb, uint supplyTime);
    event WithdrawRewards(address indexed user, uint indexed tokenId, uint totalNbuReward);
    event BalanceRewardsNotEnough(address indexed user, uint indexed tokenId, uint totalNbuReward);
    event BurnSmartLP(uint indexed tokenId);
    event UpdateSwapRouter(address indexed newSwapRouterContract, address indexed newPancakeRouterContract);
    event UpdateLpStakingBnbNbu(address indexed newLpStakingAContract);
    event UpdateLpStakingBnbGnbu(address indexed newLpStakingBContract);
    event UpdateLendingContract(address indexed newLending);
    event UpdateTokenNbu(address indexed newToken);
    event UpdateTokenGnbu(address indexed newToken);
    event UpdateMinPurchaseAmountToken(uint indexed newAmount);
    event Rescue(address indexed to, uint amount);
    event RescueToken(address indexed to, address indexed token, uint amount);
}

contract SmartLP is SmartLPStorage, IBEP721, IBEP721Metadata {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    
    address public target;

    function initialize(
        address _swapRouter, 
        address _pancakeRouter,
        address _wbnb,
        address _purchaseToken,
        address _nbuToken,
        address _gnbuToken, 
        address _bnbNbuPair, 
        address _gnbuBnbPair, 
        address _lpStakingBnbNbu, 
        address _lpStakingBnbGnbu
    ) public initializer {
        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        require(AddressUpgradeable.isContract(_swapRouter), "NimbusSmartLP_V1: Not contract");
        require(AddressUpgradeable.isContract(_pancakeRouter), "NimbusSmartLP_V1: Not contract");
        require(AddressUpgradeable.isContract(_wbnb), "NimbusSmartLP_V1: Not contract");
        require(AddressUpgradeable.isContract(_purchaseToken), "NimbusSmartLP_V1: Not contract");
        require(AddressUpgradeable.isContract(_nbuToken), "NimbusSmartLP_V1: Not contract");
        require(AddressUpgradeable.isContract(_gnbuToken), "NimbusSmartLP_V1: Not contract");
        require(AddressUpgradeable.isContract(_bnbNbuPair), "NimbusSmartLP_V1: Not contract");
        require(AddressUpgradeable.isContract(_gnbuBnbPair), "NimbusSmartLP_V1: Not contract");
        require(AddressUpgradeable.isContract(_lpStakingBnbNbu), "NimbusSmartLP_V1: Not contract");
        require(AddressUpgradeable.isContract(_lpStakingBnbGnbu), "NimbusSmartLP_V1: Not contract");

        _name = "Smart LP";
        _symbol = "SL";
         
        swapRouter = IRouter(_swapRouter);
        pancakeRouter = IPancakeRouter(_pancakeRouter);
        purchaseToken = IERC20Upgradeable(_purchaseToken);
        WBNB = IWBNB(_wbnb);
        nbuToken = IERC20Upgradeable(_nbuToken);
        gnbuToken = IERC20Upgradeable(_gnbuToken);
        lpStakingBnbNbu = ILpStaking(_lpStakingBnbNbu);
        lpStakingBnbGnbu = ILpStaking(_lpStakingBnbGnbu);
        lendingContract = ILending(address(0));

        rewardDuration = ILpStaking(_lpStakingBnbNbu).rewardDuration();
        minPurchaseAmountToken = 500 ether;
        lockTime = 30 days;

        IERC20Upgradeable(_nbuToken).approve(_swapRouter, type(uint256).max);
        IERC20Upgradeable(_gnbuToken).approve(_swapRouter, type(uint256).max);
        IERC20Upgradeable(_purchaseToken).approve(_pancakeRouter, type(uint256).max);
        IERC20Upgradeable(_bnbNbuPair).approve(address(_swapRouter), type(uint256).max);
        IERC20Upgradeable(_bnbNbuPair).approve(address(_lpStakingBnbNbu), type(uint256).max);
        IERC20Upgradeable(_gnbuBnbPair).approve(address(_lpStakingBnbGnbu), type(uint256).max);  
        IERC20Upgradeable(_gnbuBnbPair).approve(address(_swapRouter), type(uint256).max);  
    }

    receive() external payable {
        assert(
            msg.sender == address(WBNB) || msg.sender == address(swapRouter) || msg.sender == address(pancakeRouter)
        );
    }
    
    // ========================== SmartLP functions ==========================

    function buySmartLPforToken(uint256 amount) external {
      require(amount >= minPurchaseAmountToken, 'SmartLP: Token price is more than sent');
      TransferHelper.safeTransferFrom(address(purchaseToken), msg.sender, address(this), amount);

      address[] memory path = new address[](2);
      path[0] = address(purchaseToken);
      path[1] = pancakeRouter.WETH();
      (uint[] memory amountsTokenBnb) = pancakeRouter.swapExactTokensForETH(amount, 0, path, address(this), block.timestamp + 1200);
      uint256 amountBNB = amountsTokenBnb[1];
      uint256 tokenId = buySmartLP(amountBNB);
      tikSupplies[tokenId].ProvidedToken = address(purchaseToken);
      tikSupplies[tokenId].ProvidedAmount = amount;

      emit BuySmartLP(msg.sender, tokenCount, address(purchaseToken), amount, block.timestamp);
    }

    function buySmartLP(uint256 amountBNB) private returns (uint256){
      uint swapAmount = amountBNB/4;
      tokenCount = ++tokenCount;
      
      address[] memory path = new address[](2);
      path[0] = address(WBNB);
      path[1] = address(nbuToken);
      (uint[] memory amountsBnbNbuSwap) = swapRouter.swapExactBNBForTokens{value: swapAmount}(0, path, address(this), block.timestamp);

      path[1] = address(gnbuToken);      
      (uint[] memory amountsBnbGnbuSwap) = swapRouter.swapExactBNBForTokens{value: swapAmount}(0, path, address(this), block.timestamp);
      
      amountBNB -= swapAmount * 2;
      
      (, uint amountBnbNbu, uint liquidityBnbNbu) = swapRouter.addLiquidityBNB{value: amountBNB}(address(nbuToken), amountsBnbNbuSwap[1], 0, 0, address(this), block.timestamp);
      amountBNB -= amountBnbNbu;
      
      (, uint amountBnbGnbu, uint liquidityBnbGnbu) = swapRouter.addLiquidityBNB{value: amountBNB}(address(gnbuToken), amountsBnbGnbuSwap[1], 0, 0, address(this), block.timestamp);
      amountBNB -= amountBnbGnbu;
      
      uint256 noncesBnbNbu = lpStakingBnbNbu.stakeNonces(address(this));
      lpStakingBnbNbu.stake(liquidityBnbNbu);
      uint amountRewardEquivalentBnbNbu = lpStakingBnbNbu.getCurrentLPPrice() * liquidityBnbNbu / 1e18;
      _balancesRewardEquivalentBnbNbu[tokenCount] += amountRewardEquivalentBnbNbu;

      uint256 noncesBnbGnbu = lpStakingBnbGnbu.stakeNonces(address(this));
      lpStakingBnbGnbu.stake(liquidityBnbGnbu);
      uint amountRewardEquivalentBnbGnbu = lpStakingBnbGnbu.getCurrentLPPrice() * liquidityBnbGnbu / 1e18;
      _balancesRewardEquivalentBnbGnbu[tokenCount] += amountRewardEquivalentBnbGnbu;
      
      UserSupply storage userSupply = tikSupplies[tokenCount];
      userSupply.IsActive = true;
      userSupply.GnbuBnbLpAmount = liquidityBnbGnbu;
      userSupply.NbuBnbLpAmount = liquidityBnbNbu;
      userSupply.NbuBnbStakeNonce = noncesBnbNbu;
      userSupply.GnbuBnbStakeNonce = noncesBnbGnbu;
      userSupply.SupplyTime = block.timestamp;
      userSupply.TokenId = tokenCount;

      weightedStakeDate[tokenCount] = userSupply.SupplyTime;
      _userTokens[msg.sender].push(tokenCount); 
      _mint(msg.sender, tokenCount);

      return tokenCount;
    }
    
    function withdrawUserRewards(uint tokenId) external nonReentrant {
        require(_owners[tokenId] == msg.sender, "SmartLP: Not token owner");
        UserSupply memory userSupply = tikSupplies[tokenId];
        require(userSupply.IsActive, "SmartLP: Not active");
        uint nbuReward = getTotalAmountsOfRewards(tokenId);
        _withdrawUserRewards(tokenId, nbuReward);
    }
    
    function burnSmartLP(uint tokenId) external nonReentrant {
        require(_owners[tokenId] == msg.sender, "SmartLP: Not token owner");
        UserSupply storage userSupply = tikSupplies[tokenId];
        require(block.timestamp > userSupply.SupplyTime + lockTime, "SmartLP: Token is locked");
        require(userSupply.IsActive, "SmartLP: Token not active");
        uint nbuReward = getTotalAmountsOfRewards(tokenId);
        
        if(nbuReward > 0) {
            _withdrawUserRewards(tokenId, nbuReward);
        }

        lpStakingBnbNbu.withdraw(userSupply.NbuBnbStakeNonce);
        swapRouter.removeLiquidityBNB(address(nbuToken), userSupply.NbuBnbLpAmount, 0, 0,  msg.sender, block.timestamp);

        lpStakingBnbGnbu.withdraw(userSupply.GnbuBnbStakeNonce);
        swapRouter.removeLiquidityBNB(address(gnbuToken), userSupply.GnbuBnbLpAmount, 0, 0, msg.sender, block.timestamp);
        
        transferFrom(msg.sender, address(0x1), tokenId);
        userSupply.IsActive = false;
        
        emit BurnSmartLP(tokenId);      
    }

    function getTokenRewardsAmounts(uint tokenId) public view returns (uint lpBnbNbuUserRewards, uint lpBnbGnbuUserRewards) {
        UserSupply memory userSupply = tikSupplies[tokenId];
        require(userSupply.IsActive, "SmartLP: Not active");
        
        lpBnbNbuUserRewards = (_balancesRewardEquivalentBnbNbu[tokenId] * ((block.timestamp - weightedStakeDate[tokenId]) * 100)) / (100 * rewardDuration);
        lpBnbGnbuUserRewards = (_balancesRewardEquivalentBnbGnbu[tokenId] * ((block.timestamp - weightedStakeDate[tokenId]) * 100)) / (100 * rewardDuration);
    }
    
    function getTotalAmountsOfRewards(uint tokenId) public view returns (uint nbuReward) {
        (uint lpBnbNbuUserRewards, uint lpBnbGnbuUserRewards) = getTokenRewardsAmounts(tokenId);
        nbuReward = lpBnbNbuUserRewards + lpBnbGnbuUserRewards;
    }
    
    function getUserTokens(address user) public view returns (uint[] memory) {
        return _userTokens[user];
    }

    function _withdrawUserRewards(uint tokenId, uint totalNbuReward) private {
        require(totalNbuReward > 0, "SmartLP: Claim not enough");
        address tokenOwner = _owners[tokenId];
        if (nbuToken.balanceOf(address(this)) < totalNbuReward) {
            lpStakingBnbNbu.getReward();
            if (nbuToken.balanceOf(address(this)) < totalNbuReward) {
                lpStakingBnbGnbu.getReward();
            }
            emit BalanceRewardsNotEnough(tokenOwner, tokenId, totalNbuReward);
        }

        TransferHelper.safeTransfer(address(nbuToken), tokenOwner, totalNbuReward);
        weightedStakeDate[tokenId] = block.timestamp;

        emit WithdrawRewards(tokenOwner, tokenId, totalNbuReward);
    }



    // ========================== EIP 721 functions ==========================

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IBEP165) returns (bool) {
        return
            interfaceId == type(IBEP721).interfaceId ||
            interfaceId == type(IBEP721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = SmartLP.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    
    
    
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = SmartLP.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = SmartLP.ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: transfer to the zero address");
        require(SmartLP.ownerOf(tokenId) == from, "ERC721: transfer of token that is not owner");

        for (uint256 i; i < _userTokens[from].length; i++) {
            if(_userTokens[from][i] == tokenId) {
                _remove(i, from);
                break;
            }
        }
        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _userTokens[to].push(tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _remove(uint index, address tokenOwner) internal virtual {
        _userTokens[tokenOwner][index] = _userTokens[tokenOwner][_userTokens[tokenOwner].length - 1];
        _userTokens[tokenOwner].pop();
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(SmartLP.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll( address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(address from, address to,uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // ========================== Owner functions ==========================

    function rescue(address to, address tokenAddressUpgradeable, uint256 amount) external onlyOwner {
        require(to != address(0), "SmartLP: Cannot rescue to the zero address");
        require(amount > 0, "SmartLP: Cannot rescue 0");

        IERC20Upgradeable(tokenAddressUpgradeable).transfer(to, amount);
        emit RescueToken(to, address(tokenAddressUpgradeable), amount);
    }

    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "SmartLP: Cannot rescue to the zero address");
        require(amount > 0, "SmartLP: Cannot rescue 0");

        to.transfer(amount);
        emit Rescue(to, amount);
    }

    function updateSwapRouter(address newSwapRouter, address newPancakeRouter) external onlyOwner {
        require(AddressUpgradeable.isContract(newSwapRouter), "SmartLP: Not a contract");
        swapRouter = IRouter(newSwapRouter);
        pancakeRouter = IPancakeRouter(newPancakeRouter);
        IERC20Upgradeable(purchaseToken).approve(address(pancakeRouter), type(uint256).max);
        emit UpdateSwapRouter(newSwapRouter, newPancakeRouter);
    }
    
    function updateLpStakingBnbNbu(address newLpStaking) external onlyOwner {
        require(AddressUpgradeable.isContract(newLpStaking), "SmartLP: Not a contract");
        lpStakingBnbNbu = ILpStaking(newLpStaking);
        emit UpdateLpStakingBnbNbu(newLpStaking);
    }
    
    function updateLpStakingBnbGnbu(address newLpStaking) external onlyOwner {
        require(AddressUpgradeable.isContract(newLpStaking), "SmartLP: Not a contract");
        lpStakingBnbGnbu = ILpStaking(newLpStaking);
        emit UpdateLpStakingBnbGnbu(newLpStaking);
    }
    
    function updateLendingContract(address newLendingContract) external onlyOwner {
        require(AddressUpgradeable.isContract(newLendingContract), "SmartLP: Not a contract");
        lendingContract = ILending(newLendingContract);
        emit UpdateLendingContract(newLendingContract);
    }

    function updateLockTime(uint256 _lockTime) external onlyOwner {
        lockTime = _lockTime;
    }
    
    function updateTokenAllowance(address token, address spender, int amount) external onlyOwner {
        require(AddressUpgradeable.isContract(token), "SmartLP: Not a contract");
        uint allowance;
        if (amount < 0) {
            allowance = type(uint256).max;
        } else {
            allowance = uint256(amount);
        }
        IERC20Upgradeable(token).approve(spender, allowance);
    }

    function updatePurchaseToken (address _purchaseToken) external onlyOwner {
        require(AddressUpgradeable.isContract(_purchaseToken), "SmartLP: Not a contract");
        purchaseToken = IERC20Upgradeable(_purchaseToken);
        IERC20Upgradeable(_purchaseToken).approve(address(pancakeRouter), type(uint256).max);
    }

    function updateMinPurchaseAmountToken (uint newAmount) external onlyOwner {
        require(newAmount > 0, "SmartLP: Amount must be greater than zero");
        minPurchaseAmountToken = newAmount;
        emit UpdateMinPurchaseAmountToken(newAmount);
    }
}