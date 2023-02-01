//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./IPancakePair.sol";
import "./ILock.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Lock is ILock {
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
  address[] public override liquidities;
  address[] public override tokens;

  mapping(address=>TokenList[]) public liquidityList;
  mapping(address=>TokenList[]) public tokenList;
  function add(address _token, uint256 _endDateTime, uint256 _amount, address _owner, bool _isLiquidity) external override{
    require(_amount>0, "zero amount!");
    require(_token!=address(0x0),"token!");
    require(_owner!=address(0x0),"owner!");
    if(_isLiquidity){      
      require(_endDateTime>=block.timestamp+30 days,"duration!");
      address token0=IPancakePair(_token).token0();
      address token1=IPancakePair(_token).token1();
      require(token0!=address(0x0) && token1!=address(0x0), "not a liquidity");
      IERC20MetadataUpgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);
      if(liquidityList[_token].length==0){
        liquidities.push(_token);
        liquidityList[_token].push(TokenList({
            amount:_amount,
            startDateTime:block.timestamp,
            endDateTime:_endDateTime,
            owner:_owner,
            creator:msg.sender
          }));
        
        
      }else{
        bool isExisted=false;
        for(uint i=0;i<liquidityList[_token].length;i++){
          if(liquidityList[_token][i].endDateTime==_endDateTime){
            if(liquidityList[_token][i].amount==0){
              liquidityList[_token][i].startDateTime=block.timestamp;
            }
            liquidityList[_token][i].amount=liquidityList[_token][i].amount+_amount;
            isExisted=true;
            break;
          }
        }
        if(!isExisted){
          liquidityList[_token].push(TokenList({
            amount:_amount,
            startDateTime:block.timestamp,
            endDateTime:_endDateTime,
            owner:liquidityList[_token][0].owner!=address(0x0) ? liquidityList[_token][0].owner : _owner,
            creator:msg.sender
          }));
        } 
      }
      // string memory token0Name=IERC20Metadata(token0).name();
      // string memory token1Name=IERC20Metadata(token1).name();
      // string memory token0Symbol=IERC20Metadata(token0).symbol();
      // string memory token1Symbol=IERC20Metadata(token1).symbol();
      emit LiquidityLockAdded(_token, _amount, _owner, IERC20MetadataUpgradeable(token0).name(), 
      IERC20MetadataUpgradeable(token1).name(), 
      IERC20MetadataUpgradeable(token0).symbol(), 
      IERC20MetadataUpgradeable(token1).symbol(), _endDateTime, block.timestamp);    
    }else{
      require(_endDateTime>=block.timestamp+1 days,"duration!");
      IERC20MetadataUpgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);
      if(tokenList[_token].length==0){
        tokens.push(_token);
        tokenList[_token].push(TokenList({
            amount:_amount,
            startDateTime:block.timestamp,
            endDateTime:_endDateTime,
            owner:_owner,
            creator:msg.sender
          }));     
      }else{
        bool isExisted=false;
        for(uint i=0;i<tokenList[_token].length;i++){
          if(tokenList[_token][i].endDateTime==_endDateTime){
            if(tokenList[_token][i].amount==0){
              tokenList[_token][i].startDateTime=block.timestamp;
            }
            tokenList[_token][i].amount=tokenList[_token][i].amount+_amount;
            isExisted=true;
            break;
          }
        }
        if(!isExisted){
          tokenList[_token].push(TokenList({
            amount:_amount,
            startDateTime:block.timestamp,
            endDateTime:_endDateTime,
            owner:tokenList[_token][0].owner!=address(0x0) ? tokenList[_token][0].owner : _owner,
            creator:msg.sender
          }));
        }   
      }
      string memory name=IERC20MetadataUpgradeable(_token).name();
      string memory symbol=IERC20MetadataUpgradeable(_token).symbol();
      uint8 decimals=IERC20MetadataUpgradeable(_token).decimals();
      emit TokenLockAdded(_token, _amount, _owner, name, symbol, decimals, _endDateTime, block.timestamp);   
    }
    
  }
  function unlockLiquidity(address _token) external override returns (bool){
    bool isExisted=false;
    uint256 _amount;
    for(uint i=0;i<liquidityList[_token].length;i++){
      if(liquidityList[_token][i].owner==msg.sender && liquidityList[_token][i].endDateTime<block.timestamp && liquidityList[_token][i].amount>0){
        isExisted=true;
        _amount=_amount+liquidityList[_token][i].amount;
        liquidityList[_token][i].amount=0;
      }
    }
    require(isExisted==true, "no existed");
    IERC20MetadataUpgradeable(_token).safeTransfer(msg.sender, _amount);      
    for(uint i=0;i<liquidityList[_token].length;i++){
      if(liquidityList[_token][i].amount==0){
        liquidityList[_token][i]=liquidityList[_token][liquidityList[_token].length-1];
        liquidityList[_token].pop();
      }
    }
    if(liquidityList[_token].length==0){
      for(uint i=0;i<liquidities.length;i++){
        if(liquidities[i]==_token){
          liquidities[i]=liquidities[liquidities.length-1];
          liquidities.pop();
          break;
        }
      }
      
    }    
    emit UnlockLiquidity(_token, _amount, block.timestamp, msg.sender);
    return isExisted;
  }
  function unlockToken(address _token) external override returns (bool){
    bool isExisted=false;
    uint256 _amount;
    for(uint i=0;i<tokenList[_token].length;i++){
      if(tokenList[_token][i].owner==msg.sender && tokenList[_token][i].endDateTime<block.timestamp && tokenList[_token][i].amount>0){
        isExisted=true;
        _amount=_amount+tokenList[_token][i].amount;
        tokenList[_token][i].amount=0;
      }
    }
    require(isExisted==true, "no existed");
    IERC20MetadataUpgradeable(_token).safeTransfer(msg.sender, _amount);    
    for(uint i=0;i<tokenList[_token].length;i++){
      if(tokenList[_token][i].amount==0){
        tokenList[_token][i]=tokenList[_token][tokenList[_token].length-1];
        tokenList[_token].pop();
      }
    }
    if(tokenList[_token].length==0){
      for(uint i=0;i<tokens.length;i++){
        if(tokens[i]==_token){
          tokens[i]=tokens[tokens.length-1];
          tokens.pop();
          break;
        }
      }
    }
    emit UnlockToken(_token, _amount, block.timestamp, msg.sender);
    return isExisted;
  }

  function extendLock(address _token, uint256 _endDateTime, bool _isLiquidity, uint256 _updateEndDateTime)external override{
    require(_endDateTime<_updateEndDateTime, "wrong timer");
    bool isExisted=false;
    if(_isLiquidity){
      for(uint i=0;i<liquidityList[_token].length;i++){
        if(liquidityList[_token][i].owner==msg.sender && liquidityList[_token][i].endDateTime==_endDateTime && liquidityList[_token][i].amount>0){
          isExisted=true;
          liquidityList[_token][i].endDateTime=_updateEndDateTime;
        }
      }
    }else{
      for(uint i=0;i<tokenList[_token].length;i++){
        if(tokenList[_token][i].owner==msg.sender && tokenList[_token][i].endDateTime==_endDateTime && tokenList[_token][i].amount>0){
          isExisted=true;          
          tokenList[_token][i].endDateTime=_updateEndDateTime;          
        }
      }
    }
    require(isExisted, "No lock");
    emit LockExtended(_token, _endDateTime, _isLiquidity, _updateEndDateTime, msg.sender);
  }
  function getLiquidityAddresses() public view returns(address[] memory){
    return liquidities;
  }
  function getTokenAddresses() public view returns(address[] memory){
    return tokens;
  }
  function getTokenDetails(address token) public view returns(TokenList[] memory){
    return tokenList[token];
  }
  function getLiquidityDetails(address token) public view returns(TokenList[] memory){
    return liquidityList[token];
  }
}