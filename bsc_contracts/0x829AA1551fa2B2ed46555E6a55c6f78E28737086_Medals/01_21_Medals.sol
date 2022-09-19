//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IGas.sol";

contract Medals is ERC721, AccessControlEnumerable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;
    using EnumerableSet for EnumerableSet.UintSet;

    string private _baseTokenURI;
    address public gas = 0xf038F7286f060115581598c6e0E7C6110EA955e8;

    mapping(uint256 => uint256) private tokenIdIndexs;
    mapping(address => EnumerableSet.UintSet) private accountTokenIds;
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) private accountMedals;

    struct DonateConfig {
        uint256 amount;
        uint256 weight;
        uint256 medalId;
    }

    DonateConfig[] public donateConfigs;
    bytes32 public constant OPERATER_ROLE = keccak256("OPERATER_ROLE");

    constructor() ERC721("Medal", "Medal") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(OPERATER_ROLE, _msgSender());
    }

    function init(address _gas) external onlyRole(OPERATER_ROLE) {
        gas = _gas;
    }

    function addDonateConfig(
        uint256 _amount,
        uint256 _weight,
        uint256 _medalId
    ) external onlyRole(OPERATER_ROLE) {
        DonateConfig storage config = donateConfigs.push();
        config.amount = _amount;
        config.weight = _weight;
        config.medalId = _medalId;
    }

    function setDonateConfig(
        uint256 pid,
        uint256 _amount,
        uint256 _weight,
        uint256 _medalId
    ) external onlyRole(OPERATER_ROLE) {
        DonateConfig storage config = donateConfigs[pid];
        config.amount = _amount;
        config.weight = _weight;
        config.medalId = _medalId;
    }

    function setBaseTokenURI(string memory _tokenURI) external onlyRole(OPERATER_ROLE) {
        _baseTokenURI = _tokenURI;
    }

    function mint(uint256 _index) external nonReentrant {
        require(gas != address(0), "Medals: gas is zero address!");
        require(_index < donateConfigs.length, "Medals: invalid index!");
        DonateConfig memory config = donateConfigs[_index];
        IGas(gas).burnFrom(msg.sender, config.amount);
        uint256 tokenId = getTokenId(msg.sender) + _tokenId.current();
        _mint(msg.sender, tokenId);
        _tokenId.increment();
        tokenIdIndexs[tokenId] = _index;
        accountTokenIds[msg.sender].add(tokenId);
        accountMedals[msg.sender][config.medalId].add(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        accountTokenIds[from].remove(tokenId);
        accountTokenIds[to].add(tokenId);
        uint256 index = tokenIdIndexs[tokenId];
        uint256 medalId = donateConfigs[index].medalId;
        accountMedals[from][medalId].remove(tokenId);
        accountMedals[to][medalId].add(tokenId);
        super._transfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 _index = tokenIdIndexs[tokenId];
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(donateConfigs[_index].medalId), ".json"));
    }

    function getDonateConfigs() external view returns (DonateConfig[] memory) {
        return donateConfigs;
    }

    function accountMedalHolds(address _address) external view returns (uint256[] memory) {
        return accountTokenIds[_address].values();
    }

    function accountMedalTokenIds(address _address, uint256 _medalId) external view returns (uint256[] memory) {
        return accountMedals[_address][_medalId].values();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getMedalInfos(uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory medalIds, uint256[] memory weights)
    {
        medalIds = new uint256[](tokenIds.length);
        weights = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIdIndexs[tokenIds[i]];
            medalIds[i] = donateConfigs[tokenId].medalId;
            weights[i] = donateConfigs[tokenId].weight;
        }
    }

    function getTokenId(address addr) private view returns (uint256) {
        return (uint160(addr) % (2 ** 20)) + block.timestamp * (2 ** 20);
    }
}