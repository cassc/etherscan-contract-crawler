pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface ProxyEventChain {
    function eventTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract BearLab is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private m_TokenIdCounter;

    uint256 private m_MaxSupply = 4444;
    uint256 private m_SupplyStart = 1;
    uint256 private m_SupplyBase = 0;

    uint256 private m_DropSupply = 4444;

    uint256 private m_MaxMintPerAddress = 4;
    uint256 private m_MaxMintPerBear = 1;

    uint256 private m_MintPrice = 100000 ether; // 100K MSK

    uint256 private m_ClaimIdLimit = 2520;
    bool private m_ClaimEnabled = false;
    mapping(uint256 => bool) private m_ClaimedIdList;

    mapping(address => bool) private m_ProxyList;

    bool private m_IsMintable = false; // false

    string private m_baseURI;
    string private m_ContractURI;

    address private m_MSK = 0x72D7b17bF63322A943d4A2873310a83DcdBc3c8D;
    address private m_Badbear = 0x5E4aAB148410DE1CB50cDCD5108e1260Cc36d266;

    address private m_ClaimWallet = 0xA69e1e8f7afd56126452AcDbCe27374570a52D48;

    address private m_ProxyEventChainAddress;

    constructor() ERC721("Bear Labs", "BEARLABS") {
        m_ContractURI = "";
        m_ProxyEventChainAddress = address(0);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        if (m_ProxyList[_operator]) {
            return true;
        }

        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (m_ProxyEventChainAddress != address(0)) {
            ProxyEventChain(m_ProxyEventChainAddress).eventTransfer(
                from,
                to,
                tokenId
            );
        }
    }

    function totalSupply() public view returns (uint256) {
        uint256 counter = m_SupplyBase;
        for (uint256 i = m_SupplyStart; i <= m_MaxSupply; i++) {
            if (_exists(i)) counter = counter.add(1);
        }
        return counter;
    }

    function dropClaim(uint256[] memory ids) external {
        require(m_ClaimEnabled);
        IERC721 badbear = IERC721(m_Badbear);
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] <= m_ClaimIdLimit);
            if (m_ClaimedIdList[ids[i]] != true) {
                require(badbear.ownerOf(ids[i]) == _msgSender(), "No owner");
                _mintDrop(_msgSender());
                m_ClaimedIdList[ids[i]] = true;
            }
        }
    }

    function _mintDrop(address _address) private {
        m_TokenIdCounter.increment();
        uint256 tokenId = m_TokenIdCounter.current();

        require(_exists(tokenId) == false);
        require(tokenId <= m_DropSupply);

        _safeMint(_address, tokenId);
    }

    function _safeMintMultiple(address _address, uint256 _numberOfTokens)
        private
    {
        while (_numberOfTokens > 0) {
            _mintDrop(_address);
            _numberOfTokens = _numberOfTokens.sub(1);
        }
    }

    function randomReserve(address _address, uint256 _numberOfTokens)
        public
        onlyOwner
    {
        _safeMintMultiple(_address, _numberOfTokens);
    }

    function randomReserveMultiple(
        address[] memory _addresses,
        uint256[] memory _numbers
    ) external onlyOwner {
        require(_addresses.length == _numbers.length);

        for (uint256 i = 0; i < _addresses.length; i++) {
            randomReserve(_addresses[i], _numbers[i]);
        }
    }

    function mint(uint256 _numberOfTokens) public {
        require(m_IsMintable, "must be active");

        require(_numberOfTokens > 0);

        uint256 afterMintBalace = balanceOf(_msgSender()).add(_numberOfTokens);

        require(
            afterMintBalace <= m_MaxMintPerAddress,
            "Over Max Mint per Address"
        );
        IERC721 badbear = IERC721(m_Badbear);

        uint256 balanceBadbear = badbear.balanceOf(_msgSender());

        require(balanceBadbear > 0);
        require(balanceBadbear * m_MaxMintPerBear >= afterMintBalace);

        IERC20 msk = IERC20(m_MSK);
        uint256 requireAmount = m_MintPrice.mul(_numberOfTokens);

        require(
            msk.balanceOf(_msgSender()) >= requireAmount,
            "Msk balance is not enough"
        );

        msk.transferFrom(_msgSender(), m_ClaimWallet, requireAmount);

        _safeMintMultiple(_msgSender(), _numberOfTokens);
    }

    function proxyMint(address _address, uint256 _tokenId) external {
        require(m_ProxyList[_msgSender()] == true);
        _safeMint(_address, _tokenId);
    }

    function proxyBurn(uint256 _tokenId) external {
        require(m_ProxyList[_msgSender()] == true);
        _burn(_tokenId);
    }

    // ######## BearLab Config #########

    function setClaimedIdLimit(uint256 _claimIdLimit) external onlyOwner {
        m_ClaimIdLimit = _claimIdLimit;
    }

    function getClaimedIdLimit() external view returns (uint256) {
        return m_ClaimIdLimit;
    }

    function contractURI() public view returns (string memory) {
        return m_ContractURI;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        m_ContractURI = _contractURI;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        m_MintPrice = _mintPrice * (10**18);
    }

    function getMintPrice() external view returns (uint256) {
        return m_MintPrice.div(10**18);
    }

    function setDropSupply(uint256 _maxSupply) external onlyOwner {
        m_DropSupply = _maxSupply;
    }

    function getDropSupply() external view returns (uint256) {
        return m_DropSupply;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        m_baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return m_baseURI;
    }

    function setMintEnabled(bool _enabled) external onlyOwner {
        m_IsMintable = _enabled;
    }

    function getMintEnabled() external view returns (bool) {
        return m_IsMintable;
    }

    function setClaimEnabled(bool _enabled) external onlyOwner {
        m_ClaimEnabled = _enabled;
    }

    function getClaimEnabled() external view returns (bool) {
        return m_ClaimEnabled;
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress)
        external
        onlyOwner
    {
        m_MaxMintPerAddress = _maxMintPerAddress;
    }

    function getMaxMintPerAddress() external view returns (uint256) {
        return m_MaxMintPerAddress;
    }

    function setProxyList(address _proxyAddress) external onlyOwner {
        m_ProxyList[_proxyAddress] = true;
    }

    function removeProxyList(address _proxyAddress) external onlyOwner {
        m_ProxyList[_proxyAddress] = false;
    }

    function isProxyList(address _proxyAddress) external view returns (bool) {
        return m_ProxyList[_proxyAddress];
    }

    function isClaimed(uint256 _id) external view returns (bool) {
        return m_ClaimedIdList[_id];
    }

    function getClaimableCount(uint256[] memory _ids)
        external
        view
        returns (uint256)
    {
        uint256 counter = 0;
        for (uint256 i = 0; i < _ids.length; i++) {
            if (_ids[i] > m_ClaimIdLimit) continue;
            if (m_ClaimedIdList[_ids[i]] == true) continue;
            counter = counter.add(1);
        }

        return counter;
    }

    function setSupplyInfo(
        uint256 _maxSupply,
        uint256 _start,
        uint256 _base
    ) external {
        m_MaxSupply = _maxSupply;
        m_SupplyStart = _start;
        m_SupplyBase = _base;
    }

    function setProxyEventChainAddress(address _address) external onlyOwner {
        m_ProxyEventChainAddress = _address;
    }

    function getProxyEventChainAddress() external view returns (address) {
        return m_ProxyEventChainAddress;
    }

    function setMaxMintPerBear(uint256 _maxMintPerBear) external onlyOwner {
        m_MaxMintPerBear = _maxMintPerBear;
    }

    function getMaxMintPerBear() external view returns (uint256) {
        return m_MaxMintPerBear;
    }

    function setClaimWallet(address _claimWallet) external onlyOwner {
        m_ClaimWallet = _claimWallet;
    }

    function getClaimWallet() external view returns (address) {
        return m_ClaimWallet;
    }

    // ######## MSK & BADBEAR #########
    function setMskContract(address _address) external onlyOwner {
        m_MSK = _address;
    }

    function getMskContract() external view returns (address) {
        return m_MSK;
    }

    function setBadbearContract(address _address) external onlyOwner {
        m_Badbear = _address;
    }

    function getBadbearContract() external view returns (address) {
        return m_Badbear;
    }

    function withdraw() external onlyOwner {
        IERC20 msk = IERC20(m_MSK);
        msk.transfer(owner(), msk.balanceOf(address(this)));
    }
}