// SPDX-License-Identifier: MIT
//      ______               ___               __  ________
//     /_  __/__ ___ ___ _  / _ )_______ ___ _/ /_/_  __/ /  ______ __
//      / / / -_) _ `/  ' \/ _  / __/ -_) _ `/  '_// / / _ \/ __/ // /
//     /_/  \__/\_,_/_/_/_/____/_/  \__/\_,_/_/\_\/_/ /_//_/_/  \_,_/

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TeamBreakThruMetaHypeOpenEdition is ERC1155Burnable, Ownable, DefaultOperatorFilterer {
    string public name = "TeamBreakThruMetaHypeOpenEdition";
    string public symbol = "TBTMHOE";
    string public contractUri = "https://metahype.teambreakthru.net/collections/openedition/contract";
    uint256 public price = 0;
    uint256 public MintValue = 3;
    bool public isMintEnabled = false;
    mapping(address => uint256) private MintedValue;
    using Counters for Counters.Counter;
    Counters.Counter private idTracker;
    constructor() ERC1155("https://metahype.teambreakthru.net/collections/openedition/token_{id}") {
        idTracker.increment();
    }
    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
    function setContractURI(string memory newuri) public onlyOwner {
        contractUri = newuri;
    }
    function contractURI() public view returns (string memory) {
        return contractUri;
    }
    function getPrice() public view returns (uint256) {
        return price;
    }
    function setPrice(uint256 _price) public onlyOwner
    {
        price = _price;
    }
    function setMintState(bool isEnabled) public onlyOwner {
        isMintEnabled = isEnabled;
    }
    function getMintedValue(address _address) public view returns (uint256) {
        return MintedValue[_address];
    }
    function getMintValue() public view returns (uint256) {
        return MintValue;
    }
    function setMintValue(uint256 value) public onlyOwner {
        MintValue = value;
    }
    function airdrop(address[] memory to,uint256[] memory amount) public onlyOwner {
        require(
            to.length == amount.length,
            "Length mismatch"
        );
        for (uint256 i = 0; i < to.length; i++){
            for(uint256 j = 0; j < amount[i]; j++){
                _mint(to[i], idTracker.current(), 1, "");
                idTracker.increment();
            }
        }         
    }
    function mint(uint256 amount) public payable {
        require(isMintEnabled, "Mint not enabled");
        require(MintedValue[msg.sender]+amount <= MintValue, "Mint limit reached");
        require(msg.value >= price * amount, "Not enough eth");
        for(uint256 i = 0; i < amount; i++){
            _mint(msg.sender, idTracker.current(), 1, "");
            idTracker.increment();
            MintedValue[msg.sender] = MintedValue[msg.sender]+1;
        }
    }
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    function safeTransferFrom(address from,address to,uint256 tokenId,uint256 amount,bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }
    function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    function totalSupply() public view returns (uint256) {
        return idTracker.current()-1;
    }
}