pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOnlyUps.sol";


// █▀█ █▄░█ █░░ █▄█ █░█ █▀█ █▀ ░ ▀▄▀ █▄█ ▀█
// █▄█ █░▀█ █▄▄ ░█░ █▄█ █▀▀ ▄█ ▄ █░█ ░█░ █▄

// ╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋┏┓
// ╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋┃┃╋╋╋╋╋╋╋╋╋┏┛┗┓╋╋╋╋╋╋┏┛┗┓
// ┏━━┳━┳┳━━┳┳━┓┏━━┫┃╋┏━━┳━━┳━╋┓┏╋━┳━━┳━┻┓┏╋━━┓
// ┃┏┓┃┏╋┫┏┓┣┫┏┓┫┏┓┃┃╋┃┏━┫┏┓┃┏┓┫┃┃┏┫┏┓┃┏━┫┃┃━━┫
// ┃┗┛┃┃┃┃┗┛┃┃┃┃┃┏┓┃┗┓┃┗━┫┗┛┃┃┃┃┗┫┃┃┏┓┃┗━┫┗╋━━┃
// ┗━━┻┛┗┻━┓┣┻┛┗┻┛┗┻━┛┗━━┻━━┻┛┗┻━┻┛┗┛┗┻━━┻━┻━━┛
// ╋╋╋╋╋╋┏━┛┃
// ╋╋╋╋╋╋┗━━┛

// █▄░█ █▀▀ ▀█▀ █▀   █░░ █▀█ █▀▀ █▄▀ █▀▀ █▀▄   ▀█▀ █▀█   █▀▀ █▀█   █░█ █▀█
// █░▀█ █▀░ ░█░ ▄█   █▄▄ █▄█ █▄▄ █░█ ██▄ █▄▀   ░█░ █▄█   █▄█ █▄█   █▄█ █▀▀

// ONLYUPS.XYZ
// ORIGINAL CONTRACTS
// NFTS LOCKED TO GO UP

// BUILDING DEFI ON OPENSEA
// BUILDING DEFI ON OPENSEA
// BUILDING DEFI ON OPENSEA

contract FairMint is Ownable {

    IOnlyUps public onlyUpsNFT;

    mapping(address => bool) public wl;
    uint256 public wlCount;
    bool public isFM;

    uint256 public dropPrice = 1 ether / 10;

    // soft cap mint
    function mintWL() public payable
    {
        require(isFM, "fm");
        require(wl[msg.sender], "nowl");
        require(msg.value == dropPrice, "mprice");
        onlyUpsNFT.minter{value: (2 ether /10)}(msg.sender);
        onlyUpsNFT.distribute();
        //explicit sol8 style
        wlCount = wlCount - 1;
        wl[msg.sender] = false;
    }

    // soft cap mint
    function mintAll() public payable
    {
        require(isFM, "fm");
        require(msg.value == dropPrice, "mprice");
        uint256 id = onlyUpsNFT.minter{value: (2 ether /10)}(msg.sender);
        require(id < (9999 - wlCount), "wls");
        onlyUpsNFT.distribute();
    }

    function startFM(bool _is) public onlyOwner {
        isFM = _is;
    }


    function addToWl(address[] memory _wlUs) public onlyOwner {
        for (uint i=0; i<_wlUs.length; i++) {
            wl[_wlUs[i]] = true;
        }
        wlCount = wlCount + _wlUs.length;
    }

    function removeFromWl(address[] memory _wlUs) public onlyOwner {
        for (uint i=0; i<_wlUs.length; i++) {
            wl[_wlUs[i]] = false;
        }
        wlCount = wlCount - _wlUs.length;
    }

    function transferToChef(address _chef) public onlyOwner {
        onlyUpsNFT.transferOwnership(_chef);
    }

    function distributeChef() public onlyOwner {
        address payable _to = payable(msg.sender);
        _to.transfer(address(this).balance);
    }


    constructor(address _onlyups) {
        onlyUpsNFT = IOnlyUps(_onlyups);

    }

    receive() external payable {}

}