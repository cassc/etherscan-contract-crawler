// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//            _  _             _  _
//   .       /\\/%\       .   /%\/%\     .
//       __.<\\%#//\,_       <%%₿/%%\,__  .
// .    <%#/|\\%₿%#///\    /^%#%%\///%#\\
//       ""/%/""\ \""//|   |/""'/ /\//"//'
//  .     L/'`   \ \  `    "   / /  ```
//         `      \ \     .   / /       .
//  .       .      \ \       / /  .
//         .        \ \     / /          .
//    .      .    ..:\ \:::/ /:.     .     . ORDINAL LANDS.......
// ______________/ \__;\___/\;_/\________________________________
// YwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYwYw

contract OrdinalLands is ERC721A, Ownable {
    
    enum SalePhase {
        Locked,
        AccessList,
        Public
    }

    SalePhase public phase = SalePhase.Locked;

    uint256 public cost = .023 ether;
    uint256 public maxPlots = 888;
    uint256 public maxAlloc = 1;

    string public baseURI;

    address public landlord;
    struct Sig {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    constructor() payable ERC721A("OrdinalLands", "ORDL") {}

    function setLandLord(address _landlord) external onlyOwner {
        landlord = _landlord;
    }

    function verifyTitleDeed(Sig memory sig) internal view returns (bool) {
        bytes32 digest = keccak256(abi.encode(msg.sender));
        address signer = ecrecover(digest, sig.v, sig.r, sig.s);
        require(signer != address(0), "zero address");

        return signer == landlord;
    }

    function claimPlots(Sig memory sig) external payable {
        require(phase == SalePhase.AccessList, "sale not started");
        require(_totalMinted() < maxPlots, "max plots");
        require(numberMinted(msg.sender) == 0, "plot claimed");
        require(verifyTitleDeed(sig), "invalid deed");
        require(msg.value == cost, "not enough ether");

        _mint(msg.sender, 1);
    }

    function mintPlot(uint256 amount) external payable {
        require(phase == SalePhase.Public, "sale not started");
        require(_totalMinted() + amount < maxPlots + 1, "max plots");
        require(msg.value == cost * amount, "not enough eth");

        _mint(msg.sender, amount);
    }

    function reservePlots(uint256 amount) external onlyOwner {
        require(_totalMinted() + amount < maxPlots + 1, "max plots");
        
        _mint(msg.sender, amount);
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setSalePhase(SalePhase _phase) external onlyOwner {
        phase = _phase;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string calldata _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }
}