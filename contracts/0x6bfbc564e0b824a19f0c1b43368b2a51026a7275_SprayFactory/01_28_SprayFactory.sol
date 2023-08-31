// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../pings/PingAtts.sol";
import "../pings/Pings.sol";
import "../Structs.sol";
import "../IArtData.sol";
import "../utils/Randomiser.sol";
import "../enhance/IEnhancementFactory.sol";
import "../enhance/ISprayData.sol";

contract SprayFactory is IEnhancementFactory, ReentrancyGuard, Ownable{
    Pings public _pings;
    IArtData public _artData;
    ISprayData public _sprayData;
    Randomiser public _randm;

    function applyEnhancement(BaseAttributes memory baseAtts, uint skyId, string memory seed) public view virtual override returns (BaseAttributes memory){

        PaintData memory paintData = ISprayData(_sprayData).getPaintBySkyId(skyId);
        if (paintData.paintType > 0) {//is painted
            uint[] memory pingIds = paintData.pingIds;
            PingAtts memory pingAtts = _pings.getAttsById(pingIds[pingIds.length-1]);

            baseAtts.extraParams[uint(EP.PaintType)] = paintData.paintType;
            baseAtts.extraParams[uint(EP.PaletteIdx)] = pingAtts.paletteIndex;

            for(uint i=0; i < baseAtts.numPlanes; i++) {
                uint8[] memory extraParams = new uint8[](5);
                uint pingsPalletSize = _artData.getPaletteSize(baseAtts.palette);
                extraParams[uint8(PlaneEP.ColorIdx)] = _randm.randomX(seed, i, 'sprayCol', pingsPalletSize);
                extraParams[uint8(PlaneEP.ColorIdx2)] = _randm.randomX(seed, i, 'sprayCol2', pingsPalletSize);
                extraParams[uint8(PlaneEP.ColorIdx3)] = _randm.randomX(seed, i, 'sprayCol3', pingsPalletSize);
                baseAtts.planeAttributes[i].extraParams = extraParams;
            }
        }

        return baseAtts;
    }

    function setPings(address addr) external onlyOwner {
        _pings = Pings(addr);
    }

    function setArtData(address addr) external onlyOwner {
        _artData = IArtData(addr);
    }

    function setSprayData(address addr) external onlyOwner {
        _sprayData = ISprayData(addr);
    }

    function setRandomiser(address addr) external onlyOwner {
        _randm = Randomiser(addr);
    }

    function check() external view {
        require(address(_pings) != address(0), "pings addr");
        require(address(_artData) != address(0), "art addr");
        require(address(_randm) != address(0), "rnd addr");
        require(address(_sprayData) != address(0), "spdata addr");
    }

}