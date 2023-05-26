/*


                                               `:o+                        
                                            .:oyyys                        
                                         `:oyyyyyyy                        
                                       .+yyyyyyyyyy                        
                                    `:oyyyyyyyyyyyy                        
                                  `:syyyyyyyyyyyyyo                        
                                `/syyyyyyyyyyyyyyy/                        
                              `:syyyyyyyyyyyyyyyyy-                        
                             -oyyyyyyyyyyyyyyyyyys                         
                           `+yyyyyyyyyyyyyyyyyyyy:                         
                          :syyyyyyyyyyyyyyyyyyyys                          
                        `+yyyyyyyyyyyyyyyyyyyyyy.                          
                       -syyyyyyyyyyyyyyyyyyyyyy:                           
                      :yyyyyyyyyyyyyyyyyyyyyyy/                            
                     +yyyyyyyyyyyyyyyyyyyyyyy/                             
                    oyyyyyyyyyyyyyyyyyyyyyyy:                              
                  `oyyyyyyyyyyyyyyyyyyyyyyy-                               
                  oyyyyyyyyyyyyyyyyyyyyyyo`                                
                 +yyyyyyyyyyyyyyyyyyyyys:                                  
                /yyyyyyyyyyyyyyyyyyyyy/`                                   
               -yyyyyyyyyyyyyyyyyyyy+.                                     
              `syyyyyyyyyyyyyyyyys/.                                       
              +yyyyyyyyyyyyyyyyyo/:.     .:-..`                            
             -yyyyyyyyyyyyyyyyyyyo.    `/yyyyyso+:.`                       
             syyyyyyyyyyyyyyyyys:    `:syyyyyyyyyyys+-`                    
            -yyyyyyyyyyyyyyyyy+`    .oyyyyyyyyyyyyyyyyy+-`                 
            oyyyyyyyyyyyyyyyy:    `/yyyyyyyyyyyyyyyyyyyyys:`               
           .yyyyyyyyyyyyyyyo.    .oyyyyyyyyyyyyyyyyyyyyyyyys:              
           /yyyyyyyyyyyyyy+     :yyyyyyyyyyyyyyyyyyyyyyyyyyyyo.            
           oyyyyyyyyyyyyy/     /yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy:           
           yyyyyyyyyyyyy:      ``..-:/+oyyyyyyyyyyyyyyyyyyyyyyyy+          
          .yyyyyyyyyyyy-                 .:+oyyyyyyyyyyyyyyyyyyyy+         
          -yyyyyyyyyyy:                      `:oyyyyyyyyyyyyyyyyyy:        
          :yyyyyyyyyy/                          `/syyyyyyyyyyyyyyyy.       
          /yyyyyyyyy+                             `:yyyyyyyyyyyyyyy+       
          :yyyyyyyys`                      `        :yyyyyyyyyyyyyyy`      
          :yyyyyyyy.                      -ss+.      oyyyyyyyyyyyyyy-      
          -yyyyyyy/                       -yyyy-     -yyyyyyyyyyyyyy/      
          .yyyyyys`                        -osys     `yyyyyyyyyyyyyy/      
           yyyyyy:                           `.`      syyyyyyyyyyyyy:      
           oyyyys                                     oyyyyyyyyyyyyy.      
           :yyyy:                                     oyyyyyyyyyyyys       
           `yyyy`    :`                               yyyyyyyyyyyyy:       
            +yyo    `yy+-`                           .yyyyyyyyyyyys        
            .yy:    :yyyyyo:.                        +yyyyyyyyyyyy.        
             +y.    oyyyyyyyyyo+:-.`           `.-/+syyyyyyyyyyyy.         
             `y`    yyyyyyyyyyyyyyyyyssoooossyyyyyyyyyyyyyyyyyys.          
              :    `yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyo`           
                   .yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyys:             
                   -yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyys/`              
                   -yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyys/`                
                   `/oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyys+-`                  
                      .:+syyyyyyyyyyyyyyyyyyyyyyyso/-`                     
                         `.-:+osssyyyyyyyssss+/:.`                         
                                ``........``                               
                                                                           
                                                                           
                                                                           
   osssssssssssso+-         +sssssssssssso+-       -ssss+          `sssso` 
   mMMMMMMMMMMMMMMMNy.      hMMMMMMMMMMMMMMMNs`     :mMMMh`       :mMMMy`  
   mMMMy//////+oymMMMN:     hMMMy///////+yNMMMd      .hMMMm:     oNMMN+    
   mMMMo         `hMMMm     hMMMo         :MMMM-       +NMMNo  .hNMMd-     
   mMMMo          /MMMM`    hMMMo         /MMMm`        -dMMNh/mMMNs`      
   mMMMo         .hMMMh     hMMMy///////ohNMNh-          `yNMMNMMm/        
   mMMMh+++++++ohmMMNh.     hMMMNNNNNNNMMMMNy:`           `yMMMMN:         
   mMMMMMMMMMMMMMNmy/`      hMMMhooooooosyhNMNd/         `sNMMMMMm/        
   mMMMdsssssmMMMd-         hMMMo         `-mMMN:       -dMMNy+mMMNs`      
   mMMMo     -hNMMd:        hMMMo          `dMMMs     `+mMMNo` -dMMMd-     
   mMMMo      `oNMMNo`      hMMMs........-/yNMMN:    .yNMMd:    `sNMMm+    
   mMMMo        :mMMMh.     hMMMNmmmmmmNNNMMMNd/    :mMMNy.       /mMMNy`  
   hmmm+         .hmmmd-    ymmmmmmmmmmmmmdyo:`    +mmmm+          -dmmmh. 
                                                                           

A cornerstone of the Carbon ecosystem of products, the RBX token is used for
general utility purposes across our multi-token staking platform, cross-chain DEX,
leveraged liquidity pools, token launchpads, escrow tools, our decentralized fiat 
on/off ramp, and more.

Holding RBX entitles you to rewards from the revenue generated across each and
every product, special voting rights, exclusive seniority-based privileges, and the
ability to directly burn your tokens into Ether through the use of our RBX Converter.

For more information and/or business partnership agreements, please visit our 
website or contact us directly:

Web: https://rbx.ae
Email: [email protected]
Telegram: @RBXtoken
 

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./uni.sol";


contract RBX is ERC20, ERC20Burnable, ERC20Snapshot, AccessControl, ERC20Permit, ERC20Votes {
    using SafeERC20 for IERC20;
    
    bool public swapInProgress;

    struct LiquidityPairs {
      address pair;
      address router;
      address base;
    }

    bytes32 public constant AUX_ADMIN = keccak256("AUX_ADMIN");
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");

    event SetPair(address indexed pair, address indexed router);
    event WhitelistAddress(address indexed account, bool isExcluded);

    mapping(address => bool) private _whiteListed;
    mapping(address => bool) private _blacklisted;

    mapping(address => LiquidityPairs) public _routerPairs;

    uint256 public fundingFee = 20;
    uint256 public tokenThreshold = 100000 * 10 ** decimals();
    uint256 public snapStamp;

    address payable public fundingWallet;

    bool private swapping;
    bool public fundingEnabled = true;

    constructor() ERC20("RBX", "RBX") ERC20Permit("RBX") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(AUX_ADMIN, msg.sender);
        _setupRole(SNAPSHOT_ROLE, msg.sender);

        _mint(msg.sender, 100000000 * 10 ** decimals());

        fundingWallet = payable(msg.sender);

        whitelistAddress(msg.sender, true);
        whitelistAddress(address(this), true);
        //whitelistAddress(address(fundingWallet), true);

        snapStamp = block.timestamp;
    }

    function snapshot() public {
        require(
          hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
          hasRole(AUX_ADMIN, msg.sender)
          , "Insufficient privileges"
        );
        _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function whitelistAddress(address account, bool setting) public {
        require(
          hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
          hasRole(AUX_ADMIN, msg.sender)
          , "Insufficient privileges"
        );
        require(_whiteListed[account] != setting, "RBX: Account already at setting");
        _whiteListed[account] = setting;

        emit WhitelistAddress(account, setting);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20) {
        if(swapInProgress)
            require(_whiteListed[sender], "Token swap still in progress!");

        require(!_blacklisted[sender] && !_blacklisted[recipient], "Blacklisted address given");

        uint256 contractBalance = balanceOf(address(this));

        uint256 thresholdSell = contractBalance >= tokenThreshold ? tokenThreshold : contractBalance;

        if (
            fundingEnabled &&
            !swapping &&
            _routerPairs[recipient].pair == recipient &&
            !_whiteListed[sender] &&
            !_whiteListed[recipient]
        ) {
            uint256 fees = amount * fundingFee / 1000;
            amount -= fees;

            super._transfer(sender, address(this), fees);
            swapTokensByPair(fees + thresholdSell, recipient);
        }

        super._transfer(sender, recipient, amount);

        if(block.timestamp >= snapStamp + 1 days){
          _snapshot();
          snapStamp = block.timestamp;
        }
        
    }


    //TODO: ADD APPROVE FUNCTION FOR OTHER ROUTERS

    function swapTokensByPair(uint256 tokenAmount, address pair) private {
        swapping = true;

        LiquidityPairs memory currentPair = _routerPairs[pair];

        address path1 = currentPair.base;
        IUniswapV2Router02 router = IUniswapV2Router02(currentPair.router);

        // generate the pair path of token from current pair
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = path1;

        _approve(address(this), address(router), tokenAmount);

        // make the swap

        if(currentPair.base == router.WETH()){
          router.swapExactTokensForETHSupportingFeeOnTransferTokens(
              tokenAmount,
              0, // accept any amount
              path,
              fundingWallet,
              block.timestamp
          );
        } else {
          router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
              tokenAmount,
              0, // accept any amount
              path,
              fundingWallet,
              block.timestamp
          );
        }

        swapping = false;
    }

    function _addPair(address pair, address router, address base) public {
        require(
          hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
          hasRole(AUX_ADMIN, msg.sender)
          , "Insufficient privileges"
        );

        _routerPairs[pair].pair = pair;
        _routerPairs[pair].router = router;
        _routerPairs[pair].base = base;

        emit SetPair(pair, router);
    }

    function setTokenThreshold(uint256 _tokenThreshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
          hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
          hasRole(AUX_ADMIN, msg.sender)
          , "Insufficient privileges"
        );

        tokenThreshold = _tokenThreshold;
    }

    function setFundingSells(bool _setting) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
          hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
          hasRole(AUX_ADMIN, msg.sender)
          , "Insufficient privileges"
        );

        fundingEnabled = _setting;
    }

    function setFundingWallet(address payable _wallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fundingWallet = _wallet;
        _whiteListed[address(_wallet)] = true;
    }

    function blacklistAddress(address account, bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
          hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
          hasRole(AUX_ADMIN, msg.sender)
          , "Insufficient privileges"
        );
        _blacklisted[account] = value;
    }

    function setSwapInProgress(bool _swapInProgress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapInProgress = _swapInProgress;
    }
    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }


    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
    
    // internal-only function, required to override imports properly
    function _mint(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(account, amount);
    }

    function rescueTokens(address recipient, address token, uint256 amount) public returns(bool) {
        require(
          hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
          hasRole(AUX_ADMIN, msg.sender)
          , "Insufficient privileges"
        );

        require(!(_routerPairs[token].pair == token), "Can't transfer out LP tokens!");
        require(token != address(this), "Can't transfer out contract tokens!");

        IERC20(token).transfer(recipient, amount); //use of the _ERC20 traditional transfer
        
        return true;
    }

    function rescueTokensSafe(address recipient, IERC20 token, uint256 amount) public returns(bool) {
        require(
          hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
          hasRole(AUX_ADMIN, msg.sender)
          , "Insufficient privileges"
        );

        require(!(_routerPairs[address(token)].pair == address(token)), "Can't transfer out LP tokens!");
        require(address(token) != address(this), "Can't transfer out contract tokens!");
        
        token.safeTransfer(recipient, amount); //use of the _ERC20 traditional transfer
        
        return true;
    }

    function rescueEth(address payable recipient) public {
        require(
          hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
          , "Insufficient privileges"
        );
        recipient.transfer(address(this).balance);
    }
}