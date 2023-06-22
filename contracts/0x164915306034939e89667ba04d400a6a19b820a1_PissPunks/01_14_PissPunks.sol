// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

//
//     ,---.  ,-.   .---.   .---.   ,---.  .-. .-..-. .-.,-. .-.  .---.
//     | .-.\ |(|  ( .-._) ( .-._)  | .-.\ | | | ||  \| || |/ /  ( .-._)
//     | |-' )(_) (_) \   (_) \     | |-' )| | | ||   | || | /  (_) \
//     | |--' | | _  \ \  _  \ \    | |--' | | | || |\  || | \  _  \ \
//     | |    | |( `-'  )( `-'  )   | |    | `-')|| | |)|| |) \( `-'  )
//     /(     `-' `----'  `----'    /(     `---(_)/(  (_)|((_)-'`----'
//    (__)                         (__)          (__)    (_)
//
contract PissPunks is ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    uint256 public constant TOTAL_PISS_PUNKS = 9999;
    uint    public constant maxMintCount = 25;
    uint256 private _pissPunkPrice = 0.04 ether;
    uint256 private _pissPunkReserve = 300;
    bool    public  mintEnabled = false;

    string public PISS_PUNK_PROVENANCE = "";
    string public baseURI;

    address _safe = 0x83e6078409429b7d25f04015D920A499f944F5C5;

    constructor() ERC721("Piss Punks", "PSSPNKS") {}

    // setters & contract control
    function setProvenance(string memory provenance) public onlyOwner {
        PISS_PUNK_PROVENANCE = provenance;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    function setPissPunkPrice(uint256 price) external onlyOwner {
        require(price > 0, "price must be positive");
        require(price != _pissPunkPrice, "same price is already set");
        _pissPunkPrice = price;
    }
    function getPissPunkPrice() public view returns (uint256){
        return _pissPunkPrice;
    }

    function getReserveLeft() public view returns (uint256) {
        return _pissPunkReserve;
    }

    // enable / disable minting
    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    // = return all piss punks owned by a certain address
    function pissCollectionOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 ppCount = balanceOf(_owner);

        uint256[] memory ppTokenIds = new uint256[](ppCount);
        for(uint256 i; i < ppCount; i++){
            ppTokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return ppTokenIds;
    }

    // = minting
    function mint(uint256 pissPunkCount) external payable {
        require(mintEnabled, "Sale is not yet active.");
        require(pissPunkCount <= maxMintCount, "Cannot mint more than 25 Piss Punks at once");
        require(totalSupply().add(pissPunkCount) <= TOTAL_PISS_PUNKS - _pissPunkReserve, "Not enough Piss Punks left");
        require(msg.value >= pissPunkCount * _pissPunkPrice , "Incorrect ether value sent");

        for(uint i = 0; i < pissPunkCount; i++) {
            uint pissPosition = totalSupply();
            if (totalSupply() < TOTAL_PISS_PUNKS - _pissPunkReserve) {
                _safeMint(msg.sender, pissPosition);
            }
        }
    }

    // = reserve for a certain address
    function reserve(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0 && _amount <= _pissPunkReserve, "Not enough reserve left");

        uint current = totalSupply();
        for (uint i = 0; i < _amount; i++) {
            _safeMint(_to, current + i);
        }

        _pissPunkReserve = _pissPunkReserve - _amount;
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawSafe() public payable onlyOwner {
        require(payable(_safe).send(address(this).balance));
    }
}