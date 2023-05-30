// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Abramo
/// @author: FractalSoft
//  https://mandelbrot.fractalnft.art
/* ....................................................'''''''',,''''''''''................
   ................................................''''''''''',;c:;,,'''''''''.............
   ..........................................''''''''''''''',,,;col:;:;,'''''''''..........
   .......................................''''''''''''''''',,,,;:cdxol:;,''''''''''........
   .....................................''''''''''''''''',,,,;::coxkxc;;,,,'''''''''''.....
   ...............................'''''''''''''''''''',,,,,,:lxxxd;;xxdo:,,,'''''''''''....
   ...........................'''''''''''''''''''',,,,,,,,;;:oOo.   .cOx:;,,,,,,'''''''''..
   ........................''''''''''''''''''',,,,,,;;;;;;;::lkc     'xo:;;;;,,,,,,,'''''''
   ....................''''''''''''''''''''',,,,,:ldxxl::oddddxd,   .lxdooodl;;;;:lc,,'''''
   ..................''''''''''''''''''''',,,,,;;:oOOlldxdc;,....   ....,::oxlldddkxc,,''''
   ...............'''''''''''''''''''',,,,,,,,;;;:cxd..,,.                 .'cl,.ckx:,,''''
   ............'''''''''''',,,,,,,,,,,,,,,,,;;coddxxo'                          'odc;,,''''
   ..........''''''''''',,;:;;,,,,,,,,;,,;;;;:dOOd:'                            'loc;;;,'''
   .........''''''''''',,,:oo:::;;coc;;;;;;::lxxx:                               .:loxc,,''
   ......''''''''''''',,,;;lodkkdlxOxddoc:::cxxl'                                 .;oo:,,''
   ....''''''''''''',,,,,;;:cxOccol:,:lldxoldx;                                    :dl;,'''
   .''''''''''''',,,,,;;;;coxko.        .,okOl.                                    ,dl;,'''
   '''''''',,,,,,,,,;;loclokk;             ck,                                    .lo;,,'''
   '''',,,;;;,,;;;;;::lOkoox:               '.                                   .:l;,,,'''
   ,,;;;;:llc:cllccoxxOx,  ..                      Mandelbrot Set Collection    ,c:;;,,,'''
   ',,,;;;:::;:::::clodko,,:'                                                   .,c:;,,,'''
   '''''',,,,,,,,,;;;:lxxxxOo.             .l'                                    'lc;,,'''
   ''''''''''',,,,,,,;::::cxko,.          ,x0:                                     :d:,,'''
   ..''''''''''''',,,,,,;;:clkk,.,.. ..':oxdkd.                                    ,do;,,''
   ....''''''''''''',,,,,;;:lkOddxkxodkkdlcclxo,.                                  cdc;,,''
   ......'''''''''''''',,,;odollc:lkdccc:;:::dkkl.                                .:dkc,,''
   .........'''''''''''',,;lc;;;;;;::;;;;;;;:cdOOc.                              ,ddll:,'''
   ............''''''''''',,,,,,,,,,,,,,,,;;;:okkdol,                           ;dd:;,,,'''
   .............'''''''''''''''''',,,,,,,,,,,;;:cclxx,                       .'..:xl;,,''''
   ................''''''''''''''''''''',,,,,,;;;:lkd,;oo;.              ..'lddlcokkc;,''''
   ....................'''''''''''''''''''',,,,,,:dOOkxookxoocc:,   .:cclooxd::cccdo:,'''''
   ......................''''''''''''''''''',,,,,;cccl:;:clccokd.   .ckdc:cc:;;,,;:;,''''''
   .........................'''''''''''''''''''',,,,,,,,;;;;:lkc     'xd:;;,,,,,,,''''''''.
   .............................'''''''''''''''''''',,,,,,,;:okkl;..:dkx:;,,,,''''''''''...
   .................................''''''''''''''''''',,,,,;coodkddkocc;,,,'''''''''''....
   ......................................''''''''''''''''',,,,;;:cxOdc:;,,''''''''''.......
   ..........................................''''''''''''''',,,;:odlll:,,'''''''''.........
   ..............................................'''''''''''',,;ll:;,,,'''''''''...........
   .................................................'''''''''',,;;,,''''''''''.............
   ....................................................'''''''''''''''''''.................

   1978 unique pieces available
*/


import "./ERC721Tradable.sol";
import "./VIP.sol";

/**
 * @title Mandelbrot
 * Mandelbrot - a contract for non-fungible points of the Mandelbrot Set.
 */
contract Mandelbrot is ERC721Tradable {
    using SafeMath for uint256;
    constructor(address _proxyRegistryAddress) ERC721Tradable("Mandelbrot Set Collection", "BROT", _proxyRegistryAddress) {}

    bool    private _active;
    uint256 private _activeTime;
    uint256 private PRICE = 197800000000000000;    // 0.1978 ETH
    uint32  private PRESALE_TIME = 86400;         // 24 hours
    uint8   private MAX_QUANTITY = 5;            // Maximum allowed quantity to purchase
    uint8   public  COMMUNITY_QUOTA = 10;       // 10% of the sale proceeds stays in the community
    address public  COMMUNITY_WALLET = 0x229ddBd9A20e3Df3ab7f540Ec77bEB258476fEe5;
    address public  VIP_PASS_ADDRESS = 0x5645E72bcBCb9f218268e5DB15F62F016f885984;


    function baseTokenURI() override public pure returns (string memory) {
        return "https://mandelbrot.fractalnft.art/item?token_id=";
    }

    function contractURI() public pure returns (string memory) {
        return "https://mandelbrot.fractalnft.art/collection";
    }



    // Views
    function active() external view returns(bool) {
        return _active;
    }

    function timeToSale() external view returns(uint256) {
        require(_active, "Inactive");
        if (block.timestamp >= (_activeTime + PRESALE_TIME)) return 0;
        return (_activeTime + PRESALE_TIME) - block.timestamp;
    }


    // Sale

    function give_to_community(uint256 fractals) internal {
        uint256 amount = (fractals*PRICE*COMMUNITY_QUOTA).div(100);
        payable(COMMUNITY_WALLET).transfer(amount);
    }

    function pre_purchase(uint256 fractals) external payable {
        VIP(VIP_PASS_ADDRESS).transferFrom(msg.sender, address(this), fractals);
        require(_active, "Inactive");
        require(fractals <= remaining() && fractals <= MAX_QUANTITY, "Too many fractals requested");
        require(msg.value == fractals*PRICE, "Invalid purchase fractals sent");
        for (uint i = 0; i < fractals; i++) {
            mintTo(msg.sender);
        }
        give_to_community(fractals);
    }

    function purchase(uint256 fractals) external payable {
        require(_active, "Inactive");
        require(block.timestamp >= _activeTime + PRESALE_TIME, "Purchasing not active");
        require(fractals <= remaining() && fractals <= MAX_QUANTITY, "Too many fractals requested");
        require(msg.value == fractals*PRICE, "Invalid purchase amount sent");
        for (uint i = 0; i < fractals; i++) {
            mintTo(msg.sender);
        }
        give_to_community(fractals);
    }



    // Owner's functions

    function activate() external onlyOwner {
        require(!_active, "Already active");
        _activeTime = block.timestamp;
        _active = true;
    }

    function premine(uint256 fractals) external onlyOwner {
        require(!_active, "Already active");
        for (uint i = 0; i < fractals; i++) {
            mintTo(msg.sender);
        }
    }
    
    function withdraw(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }


}