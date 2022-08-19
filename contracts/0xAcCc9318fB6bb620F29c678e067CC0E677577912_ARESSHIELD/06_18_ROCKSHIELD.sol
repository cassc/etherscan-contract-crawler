// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import "./Shield.sol";

// Data
import "./TokenSwapSimpleDATA.sol";
import "./AddressTree2DATA.sol";
import "./ROCK2DATA.sol";

// Interfaces
import "./TokenSwap.sol";
import "./ROCK2INTERFACE.sol";


/*
     contract ROCK2 is ROCK2DATA, AddressTree2,                                                                    TokenSwapSimple,                                  ROCK2ERC20 {
                                  AddressTree2 is AddressTree2DATA,           AxxessControl2
                                                                              AxxessControl2 is AxxessControl2DATA
                                                                                                                   TokenSwapSimple is TokenSwapSimpleDATA, TokenSwap {
                                                                              AxxessControl2 is AxxessControl2DATA
                                                                    Shield is AxxessControl2
*/
contract ROCKSHIELD is ROCK2DATA,                 AddressTree2DATA, Shield,                                                           TokenSwapSimpleDATA,           ROCK2INTERFACE {


  constructor(string memory name_, string memory symbol_) Shield() ROCK2DATA(name_, symbol_) AddressTree2DATA() {  }




  /* Basic ERC 20 Meta Functionality */


  function name() public view override returns (string memory) {
      return _name;
  }
  function symbol() public view override returns (string memory) {
      return _symbol;
  }

  function decimals() public view override returns (uint8) {
      return _decimals;
  }


  function totalSupply() public view override returns (uint256) {
      return _totalSupplyERC20 + _totalSupplyBlocked;
  }


  function balanceOf(address account) public override view returns (uint256) {
    if (r[account].b[uint8(Balance.isNoticed)] > 0) {
      return r[account].b[uint8(Balance.erc20)];
    }
    return 0;
  }





   ////////// Gemini's Approval Timeout Implementation  - helpers ///////////////////////////

   function setMaxAllowanceTime(uint256 t ) override public onlyOperator {
     _maxAllowanceTime = t;
   }






  ////////// Gemini's Real Time Provisioning Implementation  - helpers ///////////////////////////


   function cntDig(address sender) public view override onlyMasterOrOperator returns (uint256) {
     return r[sender].dCount;
   }
   function hasDig(address sender) public view override returns (bool) {
     return r[sender].dCount>0;
   }


  // digging stuff
  function cntDigs(address account) public override view returns (uint256){
    return r[ account ].dCount;
  }

  function getDigs(address account) public override view onlyMasterOrOperator returns (Digs[] memory){
//    require( r[account].dCount > 0, "undigged" );
    uint cnt =  r[ account ].dCount;
    Digs[] memory _d  = new Digs[](cnt);

    for (uint256 i = 0; i < cnt; i++) {
      _d[ i ] = r[account].d[i];
    }

    return _d;
  }

  function setChargeAddress(address _address, uint idx) override public onlyOperator {
     chargeAddresses[idx] = _address;
  }

  function setProv( uint childcountmin, uint childsummin, uint sumnorm, uint summin) public override onlyOperator {
      digQualChildCountMin = childcountmin;  // (5x 10)
      digSumChildMin = childsummin;
      digSumNorm = sumnorm;
      digSumMin = summin;
  }



    function getPrice() public override view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) {
      return (
        _digPrice,
        _digCurrency,
        _digDecimals,
        _digForSale
      );
    }

    function setPrice( uint256 price, address currency) public override  onlyOperator {
      _digCurrency = currency;
      if (currency == address(0)) {
        _digDecimals = 18;
      } else {
        _digDecimals = ERC20(currency).decimals();
      }
      _digPrice = price;
      _digForSale = block.timestamp;
    }

    function delPrice() public override onlyOperator {
      _digForSale = 0;
    }

    function setRate( uint256 rate_) public override onlyOperator {
         _rate = rate_;
    }

    function getRate() public view override onlyMasterOrOperator returns (uint256) {
        return _rate;
   }

   function setKeep( uint256 keep_) public override onlyOperator {
        _keep = keep_;
   }

   function getKeep() public override view onlyMasterOrOperator returns (uint256) {
       return _keep;
   }



    ////////// Gemini's SelfStaking / Rocking Implementation  - helpers ///////////////////////////


  function setRocking(Rocking[] calldata _s ) override public onlyOperator {

    uint    _apyMax = 0;
    uint256 _apyTill = 0;

    for (uint256 i = 0; i < _s.length; i++) {
        s[sIndex][i] = _s[i];

        // learn latest maximum apy
        if (_s[i].apy > _apyMax) {
          _apyMax  = _s[i].apy;
          _apyTill = _s[i].till;
        }
    }
    sCount[sIndex]=_s.length;

    _apy = _apyMax;
    _apySetDate = block.timestamp;
    _apyValid = _apyTill;

    sIndex++;
  }

  function cntRocking() public override view onlyMasterOrOperator  returns (uint[] memory) {
   uint[] memory _idx  = new uint[]( sIndex );

   for (uint i = 0; i < sIndex; i++) {
     _idx[ i ] = sCount[sIndex];
   }
   return _idx;
  }

  function getRocking( uint idx ) public override  view onlyMasterOrOperator returns (Rocking[] memory) {
    if (idx >= sIndex ) { idx = sIndex-1; }

    Rocking[] memory _s  = new Rocking[]( sCount[ idx ] );

    for (uint256 i = 0; i < sCount[idx]; i++) {
      _s[ i ] = s[idx][i];
    }

    return _s;
  }


   function cntCalc(address account) public  view  override returns (uint256){
     return r[account].cCount;
   }

   function getCalc(address account, uint256 idx) public  view override onlyMasterOrOperator returns (Calcs memory){
     require( r[account].cCount > 0, "uncalced" );
     return r[account].c[idx];
   }




    // allow everyone to read out current apy
    function getAPY() public override view returns (uint256) {
       return _apy;
    }

    function getAPY( uint256 now_ ) public override  view returns (uint256 rate, uint256 from, uint256 till, bool valid ) {
      uint256 _apyTillDate = _apySetDate + _apyValid;
      return (
        _apy,
        _apySetDate,
        _apyTillDate,
        now_ >= _apyTillDate
      );
    }


    function getRock() public override view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) {
      return (
        _rockPrice,
        _rockCurrency,
        _rockDecimals,
        _rockToPayout
      );
    }

    function setRock( uint256 price, address currency) public override  onlyOperator {
      _rockCurrency = currency;
      if (currency == address(0)) {
        _rockDecimals = 18;
      } else {
        _rockDecimals = ERC20(currency).decimals();
      }
      _rockPrice = price;
      _rockToPayout = block.timestamp;
    }






    ////////// ISD's  ROCK Implementation - specific helpers ///////////////////////////


    function deployedBy() public pure returns (string memory) {
        return "Interactive Software Development LLC";
    }


    function chainPayMode(bool mode) public override  onlyOperator {
        chainPayEnabled = mode;
    }
    function getTimeStamp() public view override returns (uint256) {
        return block.timestamp;
    }


    function totalFlow(address currency) public view override returns (uint) {
        return _totalFlow[currency];
    }
    function totalBalance() public view override returns (uint256) {
        return (payable(address(this))).balance;
    }


    function isProtected(address account) public view override returns (bool) {
      if (r[account].b[uint8(Balance.isNoticed)] > 0) {
        return r[account].b[uint8(Balance.protected)] != 0;
      }
      return false;
    }


      function totals() public view  override returns (uint256 [5] memory) {
          return [
          _totalSupplyERC20,
          _totalSupplyBlocked,
          _totalSummarized,
          _totalSummarizedAPY,
          _totalDigged
        ];
      }

      function notice(address account, bool f) internal {
        RockEntry storage rm = r[ account ];
        if (rm.b[uint8(Balance.isNoticed)] == 0) {
          rm.b[uint8(Balance.isNoticed)] = block.timestamp;
          if (f == true) {
            balancedAddress.push(account);
          }
        }
      }

      function balancesOf( address account) payable public override returns (uint256 [16] memory b) {
        _totalFlow[address(0)] += msg.value;

        for (uint8 i =0; i< 16; i++) {

          // member or naked => if protected, we do not show these values
          if (r[account].b[uint8(Balance.protected)]>0 && msg.sender != account) {
            if (  i == uint8(Balance.blocked)
               || i == uint8(Balance.summarized)
               || i == uint8(Balance.summarizedAPY)
               || i == uint8(Balance.summarizedTotal)
               || i == uint8(Balance.summarizedTotalAPY)
               || i == uint8(Balance.lastBlockingTime)
               || i == uint8(Balance.rn)
            ) {
                // keep balance zero
                continue;
            }
          }

          // regged member
          if (mExists[account] == true){
            b[i] = r[account].b[i];
            continue;
          }

          // naked
          if ( i == uint8(Balance.erc20)
            || i == uint8(Balance.blocked) ) {
              b[i] = r[account].b[i];
              continue;
            }
        }

        return b;
      }


     function setFee(uint256 fee, uint96 amount ) override public onlyOperator {
       _rockFee = fee; // ETHEREUM
       _rockFeeUnit = amount;
     }
     function getFee() public override view returns (uint256 fee, uint96 unit){
       return ( _rockFee, _rockFeeUnit); // ETHEREUM
     }

     function lastBlockingOf(address account) public override view returns (uint256) {
       if (r[account].b[uint8(Balance.isNoticed)] > 0) {
         if (r[account].b[uint8(Balance.protected)]==0 || msg.sender == account) {
           uint256 r = r[account].b[uint8(Balance.lastBlockingTime)];
           return r;
         }
       }
       return block.timestamp;
     }




  ////////// OpenZeppelin's ERC20 Implementation ///////////////////////////


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return r[owner].allowances[spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }



    function transferFrom(        address sender,        address recipient,        uint256 amount    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        require(block.timestamp - r[sender].allowancesTime[_msgSender()] <= _maxAllowanceTime, "ERC20: transfer amount exceeds allowance time");

        uint256 currentAllowance = r[sender].allowances[_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, r[_msgSender()].allowances[spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        uint256 currentAllowance = r[_msgSender()].allowances[spender];
        require(currentAllowance >= subtractedValue, "XRC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    // ERC20 internals

    function _transfer(        address sender,        address recipient,        uint256 amount    ) internal virtual {
        require(sender != address(0), "IERC20: transfer from the zero address");
        require(recipient != address(0), "IERC20: transfer to the zero address");

  //      _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = r[sender].b[uint8(Balance.erc20)];
        require(senderBalance >= amount, "IERC20: transfer amount exceeds balance");
        unchecked {
            r[sender].b[uint8(Balance.erc20)] = senderBalance - amount;
        }


        /* WARNING: notice() registers balance for new unseen addresses */
        notice(recipient, true); // rescue relevant

        r[recipient].b[uint8(Balance.erc20)] += amount;

        emit Transfer(sender, recipient, amount);

  //      _afterTokenTransfer(sender, recipient, amount);
    }



    function _approve(        address owner,        address spender,        uint256 amount    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        r[owner].allowancesTime[spender] = block.timestamp;
        r[owner].allowances[spender] = amount;
        emit Approval(owner, spender, amount);
    }


    ////////// Gemini's TokenSWAP Implementation  swap Part ///////////////////////////


   /*
    WARNING: must be implemented ON SAME part where approve is implemented
   */
    function swap( address tokenAddress, uint256 tokenParam, uint256 amount ) public  {
      approve(tokenAddress,amount);
      TokenSwap(tokenAddress).paws( msg.sender, tokenParam, amount );
      approve(tokenAddress,0);
    }




    ////////// Gemini's AddressTree2 Implementation  copy of ///////////////////////////

    /* AddressTree Rescue Ops
      Copies WARNING Copies */


    /* get a list of ALL members */
    function getMemberList() public view onlyMasterOrOperator returns( address [] memory){
        return _mAddress;
    }

    /* shows count of members */
    function getMemberCount() public view onlyMasterOrOperator returns (uint256) {
      return _mAddress.length;
    }

    function getMemberRock(address memberAddress) public view onlyMasterOrOperator returns (RockEntryLight memory e) {

      require( mExists[ memberAddress ] == true, "member does not exists");

      RockEntry storage rm = r[ memberAddress ];

      e.delegatePaymentToAddress = rm.delegatePaymentToAddress;
      e.b = rm.b;
      e.dCount = rm.dCount;
      e.cCount = rm.cCount;

      return e;
    }


    function getMember(address memberAddress) public view onlyMasterOrOperator returns (Entry memory) {

      require( mExists[ memberAddress ] == true, "member does not exists");

      return m[ memberAddress ];
    }






  }