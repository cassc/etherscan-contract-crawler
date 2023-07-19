// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// ██████╗░██╗░░░██╗███╗░░██╗██╗░░██╗░██████╗
// ██╔══██╗██║░░░██║████╗░██║██║░██╔╝██╔════╝
// ██████╔╝╚██╗░██╔╝██╔██╗██║█████═╝░╚█████╗░
// ██╔═══╝░░╚████╔╝░██║╚████║██╔═██╗░░╚═══██╗
// ██║░░░░░░░╚██╔╝░░██║░╚███║██║░╚██╗██████╔╝
// ╚═╝░░░░░░░░╚═╝░░░╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░                                                                        

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma abicoder v2;

abstract contract FLUXOV {
  function burn(address account, uint256 id, uint256 value) public virtual;
}

contract TheNameless is ERC721A, Ownable {

    uint256 public maxPVNKS = 3333; 
    uint256 public foundersReserve = 30; // Reserve PVNKS for founders, marketing etc. - adjustable 

    bool public claimIsActive = false;
    bool public burnIsActive = false;

    string private _baseTokenURI;
    string public jailbreakSequence = ""; // Provenance Hash

    mapping(address => uint256) private availablePVNKS; // Free mint allocation, you're welcome ;)

    FLUXOV private FluxOverload = FLUXOV(0x84D236c81a3cF7Da83e94F28435dBB0D12840438); //Mainnet

    constructor() ERC721A("The Nameless", "Nameless") { }
    
    function reservePVNKS(address _to, uint256 _reserveAmount) public onlyOwner {        
        require(_reserveAmount > 0 && _reserveAmount <= foundersReserve, "unable to mint any further for founders");
        foundersReserve = foundersReserve - _reserveAmount;
        _safeMint(_to, _reserveAmount);
    }

    function updateFoundersReserve(uint256 newReserve) public onlyOwner {
        foundersReserve = newReserve;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        jailbreakSequence = provenanceHash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function flipClaimState() public onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function flipBurnState() public onlyOwner {
        burnIsActive = !burnIsActive;
    }

    // Utility 

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function remainingPVNKSAllocation(address _address) external view returns (uint) {
    return availablePVNKS[_address];
    }

    // Burning

    function burnToMint1(uint256 burnMint1) external {
        require(burnIsActive, "Burn is not active");

                FluxOverload.burn(msg.sender, 1, burnMint1);
                _safeMint(msg.sender, burnMint1);
    }  

    function burnToMint2(uint256 burnMint2) external {
        require(burnIsActive, "Burn is not active");

                FluxOverload.burn(msg.sender, 2, burnMint2);
                _safeMint(msg.sender, burnMint2);
    }  

    // PVNKS Allocations
 
    function updateAllocation(address[] memory _addresses, uint[] memory _PVNKSToClaim) external onlyOwner {
        require(_addresses.length == _PVNKSToClaim.length, "Invalid snapshot data");
        for (uint i = 0; i < _addresses.length; i++) {
            availablePVNKS[_addresses[i]] = _PVNKSToClaim[i];
        }
    }

    function claimAllocation(uint PVNKSMint) external {
        require(claimIsActive, "Claim is not active");
        require(PVNKSMint <= availablePVNKS[msg.sender], "Invalid PVNKS Mint!");
        require(totalSupply() + PVNKSMint <= maxPVNKS, "Supply would be exceeded");

            availablePVNKS[msg.sender] = availablePVNKS[msg.sender] - PVNKSMint;
            _safeMint(msg.sender, PVNKSMint);
    } 

}