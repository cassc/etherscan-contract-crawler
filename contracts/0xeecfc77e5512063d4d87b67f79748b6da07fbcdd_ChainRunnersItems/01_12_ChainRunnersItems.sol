import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ItemManagerPermissions.sol";

interface ChainRunnersItemRenderer {
    function uri(uint256 id) external view returns (string memory);
}

contract ChainRunnersItems is ERC1155Supply, ItemManagerPermissions {

    address private _rendererAddress;
    mapping(uint256 => uint256) private _mintEndTimes;
    mapping(uint256 => uint256) private _maxSupplies;
    mapping(uint256 => uint256) private _totalSupplies;

    error MintingEnded();
    error MaxTokenSupplyExceeded();
    error ChangeMaxTokenSupply();
    error ChangeMintingEndDate();
    error CallerNotOwnerNorApproved();

    constructor() ERC1155('') {}

    // MODIFIERS
    modifier whenMintActive(uint256 id) {
        if (!isMintActive(id)) revert MintingEnded();
        _;
    }

    modifier whenMintBatchActive(uint256[] memory ids) {
        for (uint256 i; i < ids.length; i++) {
            if (!isMintActive(ids[i])) revert MintingEnded();
        }
        _;
    }

    // ADMIN FUNCTIONS
    function setMaxSupply(uint256 id, uint256 supply) public onlyOwner {
        if (_maxSupplies[id] > 0) revert ChangeMaxTokenSupply();
        _maxSupplies[id] = supply;
    }

    function setMintEndTime(uint256 id, uint256 endTime) public onlyOwner {
        if (_mintEndTimes[id] > 0) revert ChangeMintingEndDate();
        _mintEndTimes[id] = endTime;
    }

    function setRendererAddress(address rendererAddress) public onlyOwner {
        _rendererAddress = rendererAddress;
    }

    // READ FUNCTIONS
    function maxSupply(uint256 id) public view returns (uint256) {
        return _maxSupplies[id];
    }

    function mintEndTime(uint256 id) public view returns (uint256) {
        return _mintEndTimes[id];
    }

    function isMintActive(uint256 id) public view returns (bool) {
        return _mintEndTimes[id] == 0 || (block.timestamp <= _mintEndTimes[id]);
    }

    function rendererAddress() public view returns (address) {
        return _rendererAddress;
    }

    // MINTING FUNCTIONS
    function mint(address[] calldata addresses, uint256 id, uint256 amount) external onlyItemManager whenMintActive(id) {
        for (uint256 i; i < addresses.length; i++) {
            if (_maxSupplies[id] > 0 && (amount + _totalSupplies[id]) > _maxSupplies[id]) revert MaxTokenSupplyExceeded();
            // Update supply before mint for reentrancy protection
            _totalSupplies[id] += amount;
            _mint(addresses[i], id, amount, '');
        }
    }

    function mintBatch(address[] calldata addresses, uint256[] calldata ids, uint256[] calldata amounts) external onlyItemManager whenMintBatchActive(ids) {
        require(ids.length == amounts.length);
        for (uint256 i; i < ids.length; i++) {
            if (_maxSupplies[ids[i]] > 0 && (_totalSupplies[ids[i]] + (amounts[i] * addresses.length)) > _maxSupplies[ids[i]]) revert MaxTokenSupplyExceeded();
            // Update supply before mint for reentrancy protection
            _totalSupplies[ids[i]] += (amounts[i] * addresses.length);
        }
        for (uint256 j; j < addresses.length; j++) {
            _mintBatch(addresses[j], ids, amounts, '');
        }
    }

    // BURNING FUNCTIONS
    function burn(address[] calldata addresses, uint256 id, uint256 amount) external onlyItemManager {
        for (uint256 i; i < addresses.length; i++) {
            if (addresses[i] != _msgSender() && !isApprovedForAll(addresses[i], _msgSender())) revert CallerNotOwnerNorApproved();
            _burn(addresses[i], id, amount);
        }
    }

    function burnBatch(address[] calldata addresses, uint256[] calldata ids, uint256[] calldata amounts) external onlyItemManager {
        for (uint256 i; i < addresses.length; i++) {
            if (addresses[i] != _msgSender() && !isApprovedForAll(addresses[i], _msgSender())) revert CallerNotOwnerNorApproved();
            _burnBatch(addresses[i], ids, amounts);
        }
    }

    // RENDERING FUNCTIONS
    function uri(uint256 id) public view override returns (string memory) {
        ChainRunnersItemRenderer renderer = ChainRunnersItemRenderer(_rendererAddress);
        return renderer.uri(id);
    }
}