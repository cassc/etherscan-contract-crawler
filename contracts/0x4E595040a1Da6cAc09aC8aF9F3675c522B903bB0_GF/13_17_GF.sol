// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "solady/tokens/ERC20.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {DateTimeLib} from "solady/utils/DateTimeLib.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibBitmap} from "solady/utils/LibBitmap.sol";
import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";
import {LinearVRGDA} from "VRGDAs/LinearVRGDA.sol";

import {Staking} from "src/Staking.sol";
import {CBT} from "src/bonding/CBT.sol";

import "forge-std/console.sol";

// SSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##################################
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS######################################################
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS###############S################################@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##SSSSSSSSSSS###########################################@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%%%%%%%S%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS######################################@@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%%%%%%%S%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS###################################@@@@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%%%%%%%SSSS###SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#################################@@@@@@@@@
// SSSSSSSSSSSSSSSSS######SSSSS%%%%%%%%%%%%SSSSS##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS###############################@@@@@@@@
// SSSSSSSSSSSSSSSSS%????????%SSSSSSSSSSSSSSSS##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS###############################@@##@@@
// SSSSSSSSSSSSSS##?;::;+**+:;?%SSSSSSSSSSSSSS##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#############################SS#@@
// SSSSSSSSSSSSSS##?;,:*#@#%;::+S#SSSSSSSSSSSS%%SSSSSSSSSSSSSSSSSSSSS##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS###############%%?%%%#######@@@@
// SSSSSSSSSSSSSS##?;,:*#@#?;,:*##SSSSSSSSSS#SS%%%SSS##SSSSS####SSSS%??%SSSS##########SSSSSSSS########SSSSSSSSSSSSSSS################S%?;;++;;?%S######@@
// SSSSSSSSSSSSSSS#?;::+?%?*;;+%#@S%???%SSSS%???%%%%%??%SSSS%??%SS#%?**?S##S%????????%S#SSS##S%??????%##SSSSSSSSSSS##S%%????%%#######%+::+SS?**?S####S%%#
// SSSSSSSSSSSSSSS#?;::;+**+:;?S#@#?;::+S##?;::+%##%;::+S##%;::+S##S%%%S###%;::::;++;;?%SS#S%*;;+**+;;?%SSSSSSSSSS#S%?;;+**+;;?%S####S+::[email protected]####@##SSS%%%
// SSSSSSSSSSSSSSS#?;::*#@#%;::*S##?;,:*#@#?;,:+#@#?;,:+#@#?;,:+#@#%;::+S##%;:,:+?#%;::+S##%;::[email protected]#%;::+S##SSSSSS##%;::[email protected]@%;::+S##S%?;::;?%S###SSSSSSSS%
// SSSSSSSSSSSSSSS#?;::*#@#?;,:*#@#?;,:*#@#?;,:*#@#?;,:*#@#%;::+#@#?;,:+#@#?;::[email protected]@%;::[email protected]#%;::[email protected]#%;::[email protected]#SSSSSS##%;::[email protected]#%;::[email protected]#S?+:,::+?S##SSSSSSSSS#
// SSSSSSSSSSSSSSS#?;::*#@#?;,:*#@S?:,:*#@#%;,:+#@#%*;:;?%?*:,:+#@#?;::+#@#%;::[email protected]#?;::[email protected]#%;,:+#@#%;::[email protected]#SSSSSS##%;,:[email protected]@%;::[email protected]###%;::[email protected]@##SSSSS#####
// SSSSSSSSSSSSSSS#?;,:;?%?*;;+%##S?*;:;?%?*:;+%#@#S#%*+***+:::+#@#?;,:+#@@%;,:[email protected]#?;,:[email protected]#%*+:;?%%*;::[email protected]#SSSSSSS#S*+:;?%%*;::[email protected]###%;::[email protected]#SSSSSS######
// SSSSSSSSSSSSSSSS%*+*******%#@##%%S%*+*****%#@@#SSSSS####%;::[email protected]#%*+*%#@#%***%#@#%*+*%#@#S#S*****+:::[email protected]#SSSSSSSS##S*+***+:::[email protected]###%;::[email protected]#SS##########
// SSSSSSSSSSSSSSSSSS###########SS%%%%SS#####@##SSSSS###S##%;,:[email protected]#SS#@@@@####@@@#SSS#####SS#######%;::[email protected]#SSSSSSSSS#######%+::[email protected]###S+::[email protected]#############
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%SSSSSSSSSSSS%??%SS%*:;+%#@#SS########@@#SSSSSSSSSSSS%??%S##%;::[email protected]#SSSSSSSSS%??%S##%+::[email protected]#S%*;:+?#@#############
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%SSSSSSSSSSS%*+;;?*;;+%#@@#SSSS######@###SSSSSSSSSSSS?+:;?%?*;:+?#@#SSSSSSS#S?+:;*%%*;:+?#@#S?**?#@@@###########@#
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%%SSSSSSS##%*****%#@@#SSSSSSS#####@#######SSSSSSSS#S*+*****?#@@#SSSSSSSSS##S*******?#@@##SS##@@@#############@#
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%SSSSSSSSSSSSSS#######SSSSSSSSS##@@#########SSSSSSSSSSS#########SSSSSSSSSSSSSSS#######@##SSSSS#################@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##SSSSSSSSSSSSSSSSSSSSSSSSSSSS####SSSSSSSSSSS#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#########@@@###@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#########@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%%SSS%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS####SSS#@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS###SSSS#@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%%%%SSSS##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##SSSS##@@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%SSSS###SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#SSSS#@@@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%SSSSSSS#@@##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#@@@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#@@####SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%SSSSS#@@@@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##SSSSSSSSSS###########SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#@@@@@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%SSSSSSSS#######S%%S#####SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##@@@@@@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%?%%SSS###SSSSSSS%%%%SS######SSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%SS####SS##@@@@@@@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS??????????%SS##S%??%%%%%%%%S########################SSSSSSSSSS%??%SSSSSSS##@@@@@@@@@@@@
// #####SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%????????%%%%%%%%%%%%%%%%S#SS####################SSSSSSSSSSSSSSS%%%SSS##@@@@@@@@@@@@
// SSSSSSSSSSSS####SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS####SS%???????%%%%%%%%%%%%%%%SS%%#####################SSSSSSSSSSSSSSSSSSSS##@@@@@@@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS########SS%????????%%%%%%%%%%%%%%%??%S#####################SSSSSSSSSSSSSSSSSSSS#@@@@@@@@@@@@
// SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#####SSSSSS???????%%%%%%%%%%%%%%%S%???%#######################SSSSSSSSSSSSSSSSSSS#@@@@@@@@@@@@
// ###########SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#######SSS##S%?%%%%%%%%%%%%%%%%%%%%%?????%S######################SSSSSSSSSSSSSSSSSS#@@@@@@@@@@@@
// ############SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS########SS###S%?%%%%%%%%%%%%%%%%%SS%?**???*?S######################SSSSSSSSSSSSSSSSS#@@@@@@@##@@#
// ################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#############S%%%%%%%%%%%%%%%%SSSSS%?***???%S#######################SSSSSSSSSSSSSSSS#@@@@@@@@@@@#
// ##################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS###########S%%%%%??%%%%%%SSSSSSSSS%%??%%%%S#########################SSSSSSSSSSSSSS#@@@@@@@@@@@@
// ###############SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#######SSS%%%%??%%%%%%%%S%%%%%SSSSSSSSSSS##########################SSSSSSSSSSSS##@@@@@@@@@@@@
// ##################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%*?%SSSSS%%%%%%%%%%%%%%%%%%%%%%%%%SS##SSSS#############################SSSSSSSSSSS##@@@@@@@@@@@@
// #######################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?*????%%%%%%%%%%%%%%%%%%%%%%%%%%%%SS###S##############################SSSSSSSSSSSS##@@@@@@@@@@@
// #######################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?*???%%%%%%%%%%%%%%%%%%%%%%%%%%%%%SS##################################SSSSSSSSSSSSS##@@@@@@@@@@
// #######################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS?**???%%%%??????%%%%%%%%%%%%%??%%S#@@##SS#S###########################SSSSSSSSSSSSS##@@@@@@@@@@
// ########################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS?***???%????????????%%%????%%SSSS#####################################SSSSSSSSSSSSS##@@@@@@@@@@
// ###########################SSSSSSSSSSSSSSSSSSSSSSSSSSSS?****??%%%??????????????%%%S####SSSS############SSSSSSS###############SSSSSSSSSSSSSS##@@@@@@@@@
// ###########################SSSSSSSSSSSSSSSSSSSSSSSSSSSS?****?%S#SS%%%SSSSSS%%%S########SSSSSSSSSSSSSSSSSSSSSSSSSSSS##########SSSSSSSSSSSSSSS#@@@@@@@@@
// #############################SSSSSSSSSSSSSSSSSSSSSSSSSS%%???%S###########################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS######SSSSSSSSSSSSSSS#@@##@@@@#
// ###############################SSSSSSSSSSSSSSSSSSSSSSSS#####SS#######################################SSSSSSSSSSSSSSSSSSSSSS#SSSSSSSSSSSSSSSSS##%S#@#SS
// ###############################SSSSSSSSSSSSSSSSSSSSSSSS##########################################################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#S%%S
// #################################SSSSSSSSSSSSSSSSSSSSSSS##S%%##SS######################SSSSSSSSSSSS############################SSSSSSSSSSSSSSSSSSS%%SS
// ##################################SSSSSSSSSSSSS#SSSSSSSSS%?*???*?############S#######SSSSSSSSSSSSSSSSSSSSSSSSSSSS##############SSSSSSSSSSSSSSSSSS%%%SS
// ####################################SSSSSSSSSSSS##SSSS#S%+*S%*++?S#######SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%S
// ####################################SSSSSSSSSSSSSSSSSS#SS?%SS%?**%%SSSSSSSSSSSSSSSS#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%S
// #################################SSSSSSSSSSSSSSSSSSSSSSSSSS###S?*?%S#################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%
// @##################################SSSSSSSSSSSSSSSSSSSSSSSSSSSS%%S###################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
// @###################################SSSSSSSSSSSSSSSSSSSSSSSSSS#######################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS########SSS##
// @@@#################################SSSSSSSSSSSSSSSSSSSSSSSSSS#######################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##@@@@@@#####@
// @@@@@###############################SSSSSSSSSSSSSSSSSSSSSSSSSS####S##################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS###@#######@@
// @@@@@###############################SSSSSSSSSSSS##SSSSSSSSSSSS#####################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#@@@@@##@@@
// @@@@@@@############################SSSSSSSSSSSSSSSSSSSSSSSSSSSS##################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##@@@@@@@@@
// @@###@@@@########################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS####################SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#####@@@@

contract GF is ERC20, Ownable, LinearVRGDA {
    using FixedPointMathLib for uint256;
    using LibBitmap for LibBitmap.Bitmap;

    event Claimed(address indexed user, uint256 amount);

    error BlessingComplete();

    uint256 public constant maxSupply = 12 * 10 ** 9 * 10 ** 18; // 12 billion
    uint256 public constant targetPricePerToken = 0.00000055 ether;
    uint256 public constant devTax = 400;
    address immutable dev;

    uint256 public toSell = 114 * 10 ** 8 * 10 ** 18; // 11.4 billion
    uint256 public tokensSold;
    uint256 public startTime;

    Staking public staking;
    CBT public cbt;

    LibBitmap.Bitmap internal claims;
    bytes32 internal merkleRoot; // 1.5% airdropped

    // goes down 5% per unit of time
    // aiming to sell 20% of tokens per unit of time
    // 1 unit of time = 1 hour
    constructor() LinearVRGDA(int256(targetPricePerToken), 0.05e18, 2280000000 * 10 ** 18) {
        _initializeOwner(msg.sender);
        dev = msg.sender;
        startTime = block.timestamp;
        staking = new Staking();
        cbt = new CBT(100000); // 10% CW

        _mint(msg.sender, 420000000 * 10 ** 18); // premint 3.5% for cex
    }

    // ######################################
    // ######################################

    function name() public pure override returns (string memory) {
        return "girlfriend";
    }

    function symbol() public pure override returns (string memory) {
        return "GF";
    }

    function secretMessage() public pure returns (string memory) {
        return "buying gf";
    }

    // ######################################
    // ######################################

    function taxRate() public view returns (uint256 bps) {
        // max 10%, min 0%
        bps = 1000 - (staking.totalStaked().divWadUp(totalSupply()) / 10 ** 15);
    }

    function getTimePassed() internal view returns (int256 t) {
        t = int256(DateTimeLib.diffHours(startTime, block.timestamp)) * 1e18;
    }

    function getPrice() external view returns (uint256 price) {
        price = getVRGDAPrice(getTimePassed(), tokensSold);
    }

    // ######################################
    // ######################################

    /// @param tokensToBuy The amount of tokens to buy, not scaled by 1e18
    function getBlessed(uint256 tokensToBuy) external payable {
        uint256 tokensToBuyScaled = tokensToBuy * 1e18;
        unchecked {
            toSell -= tokensToBuyScaled;
            uint256 price = getVRGDAPrice(getTimePassed(), tokensSold);
            tokensSold += tokensToBuyScaled;
            require(msg.value >= tokensToBuy * price, "UNDERPAID");
            _mint(msg.sender, tokensToBuyScaled);
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - tokensToBuy * price);
            // dev tax
            SafeTransferLib.safeTransferETH(dev, ((tokensToBuy * price) * devTax) / 10000);
        }
    }

    function claim(uint256 index, uint256 amount, bytes32[] calldata proof) external payable {
        require(!claims.get(index), "Already claimed.");
        bytes32 node = keccak256(abi.encodePacked(msg.sender, index, amount));
        require(MerkleProofLib.verify(proof, merkleRoot, node), "Invalid proof.");
        claims.set(index);
        _mint(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    // ######################################
    // ######################################

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address _staking = address(staking);
        uint256 _taxRate = taxRate();
        // take tax for stakers
        uint256 tax;
        if (to != _staking && to != address(cbt)) {
            tax = (amount * _taxRate) / 10000;
            // burn 80% of tax
            super._burn(from, (tax * 8000) / 10000);
            // 20% left sent to staking contract
            super.transferFrom(from, _staking, (tax * 2000) / 10000);
        }
        return super.transferFrom(from, to, amount - tax);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address _staking = address(staking);
        uint256 _taxRate = taxRate();
        // take tax for stakers
        uint256 tax;
        if (msg.sender != _staking && msg.sender != address(cbt)) {
            tax = (amount * _taxRate) / 10000;
            // burn 80% of tax
            super._burn(msg.sender, (tax * 8000) / 10000);
            // 20% left sent to staking contract
            super.transfer(_staking, (tax * 2000) / 10000);
        }
        return super.transfer(to, amount - tax);
    }

    // ######################################
    // ######################################

    function startCBT() external onlyOwner {
        cbt.start{value: address(this).balance}();
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}