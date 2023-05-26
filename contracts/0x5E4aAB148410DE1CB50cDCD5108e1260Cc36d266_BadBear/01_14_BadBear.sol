pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface NftStaking {
    function eventTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract BadBear is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private m_TokenIdCounter;

    uint256 private constant MAX_SUPPLY = 5555;

    uint256 private m_MaxMintPerAddress = 5;

    address private MISHKA2 = 0x72D7b17bF63322A943d4A2873310a83DcdBc3c8D;
    uint256 private m_MskMinHold = 50000 * 10**18;

    uint256 private m_PreMintPrice = 0.1 ether; // 0.1Eth
    uint256 private m_PublicMintPrice = 0.15 ether; // 0.1Eth

    mapping(address => bool) private m_WhiteList;

    mapping(address => bool) private m_ProxyList;

    mapping(uint256 => bool) private m_BurnList;

    mapping(address => bool) private m_DevWallet;

    address[] private m_WhiteNftList;

    bool private m_IsMintable = false; // false
    bool private m_IsPublic = false;

    string private m_baseURI;
    string private m_ContractURI;

    address private m_StakingAddress;

    constructor() ERC721("Bad Bears", "BADBEAR") {
        m_ContractURI = "https://nft.badbears.io/api/contract/info.json";
        m_StakingAddress = address(0);
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
        if (m_StakingAddress != address(0)) {
            NftStaking(m_StakingAddress).eventTransfer(from, to, tokenId);
        }
    }

    function totalSupply() public view returns (uint256) {
        uint256 counter = 0;
        for (uint256 i = 1; i <= MAX_SUPPLY; i++) {
            if (_exists(i)) counter = counter.add(1);
        }
        return counter;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _safeMintMultiple(address _address, uint256 _numberOfTokens)
        private
    {
        while (_numberOfTokens > 0) {
            m_TokenIdCounter.increment();
            uint256 tokenId = m_TokenIdCounter.current();

            if (_exists(tokenId) || m_BurnList[tokenId]) continue;

            require(tokenId <= MAX_SUPPLY);
            _safeMint(_address, tokenId);
            _numberOfTokens = _numberOfTokens.sub(1);
        }
    }

    function customReserve(address _address, uint256[] memory ids)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] <= MAX_SUPPLY);
            require(!_exists(ids[i]), "Token id exists.");
            if (m_BurnList[ids[i]]) m_BurnList[ids[i]] = false;

            _safeMint(_address, ids[i]);
        }
    }

    function randomReserve(address _address, uint256 _numberOfTokens)
        external
        onlyOwner
    {
        _safeMintMultiple(_address, _numberOfTokens);
    }

    function mint(uint256 _numberOfTokens) public payable {
        require(m_IsMintable, "must be active");

        require(_numberOfTokens > 0);

        require(
            balanceOf(msg.sender).add(_numberOfTokens) <= m_MaxMintPerAddress,
            "Over Max Mint per Address"
        );

        if (m_IsPublic) {
            require(msg.value == m_PublicMintPrice.mul(_numberOfTokens));
        } else {
            IERC20 mishkaV2 = IERC20(MISHKA2);
            require(
                m_WhiteList[msg.sender] ||
                    mishkaV2.balanceOf(msg.sender) >= m_MskMinHold ||
                    isExistWhiteNft(msg.sender)
            );
            require(msg.value >= m_PreMintPrice.mul(_numberOfTokens));
        }

        _safeMintMultiple(msg.sender, _numberOfTokens);
    }

    function devMint(uint256 _numberOfTokens) external {
        require(m_DevWallet[msg.sender]);

        _safeMintMultiple(msg.sender, _numberOfTokens);
    }

    function burn(uint256 _tokenId) external onlyOwner {
        _burn(_tokenId);
        m_BurnList[_tokenId] = true;
    }

    /////////////////////////////////////////////////////////////

    function setWhiteList(address _address) public onlyOwner {
        m_WhiteList[_address] = true;
    }

    function setWhiteListMultiple(address[] memory _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            setWhiteList(_addresses[i]);
        }
    }

    function removeWhiteList(address _address) external onlyOwner {
        m_WhiteList[_address] = false;
    }

    function isWhiteListed(address _address) external view returns (bool) {
        return m_WhiteList[_address];
    }

    function setDevWallet(address _address) external onlyOwner {
        m_DevWallet[_address] = true;
    }

    function removeDevWallet(address _address) external onlyOwner {
        m_DevWallet[_address] = false;
    }

    function setWhiteNft(address _address) public onlyOwner {
        require(!isWhiteNft(_address));

        for (uint256 i = 0; i < m_WhiteNftList.length; i++) {
            if (m_WhiteNftList[i] == address(0)) {
                m_WhiteNftList[i] = _address;
                return;
            }
        }

        m_WhiteNftList.push(_address);
    }

    function removeWhiteNft(address _address) external onlyOwner {
        require(isWhiteNft(_address));

        for (uint256 i = 0; i < m_WhiteNftList.length; i++) {
            if (_address == m_WhiteNftList[i]) m_WhiteNftList[i] = address(0);
        }
    }

    function isWhiteNft(address _address) public view returns (bool) {
        for (uint256 i = 0; i < m_WhiteNftList.length; i++) {
            if (_address != address(0) && m_WhiteNftList[i] == _address)
                return true;
        }
        return false;
    }

    function isExistWhiteNft(address _address) public view returns (bool) {
        for (uint256 i = 0; i < m_WhiteNftList.length; i++) {
            if (m_WhiteNftList[i] != address(0)) {
                if (ERC721(m_WhiteNftList[i]).balanceOf(_address) > 0)
                    return true;
            }
        }
        return false;
    }

    function getWhiteNftList()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return m_WhiteNftList;
    }

    // ######## BadBear Config #########

    function getMaxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function contractURI() public view returns (string memory) {
        return m_ContractURI;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        m_ContractURI = _contractURI;
    }

    function getPreMintPrice() external view returns (uint256) {
        return m_PreMintPrice;
    }

    function setPreMintPrice(uint256 _preMintPrice) external onlyOwner {
        m_PreMintPrice = _preMintPrice;
    }

    function getPublicMintPrice() external view returns (uint256) {
        return m_PublicMintPrice;
    }

    function setPublicMintPrice(uint256 _publicMintPrice) external onlyOwner {
        m_PublicMintPrice = _publicMintPrice;
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

    function setPublicMintEnabled(bool _enabled) external onlyOwner {
        m_IsPublic = _enabled;
    }

    function getPublicMintEnabled() external view returns (bool) {
        return m_IsPublic;
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

    function setStakingAddress(address _address) external onlyOwner {
        m_StakingAddress = _address;
    }

    function getStakingAddress() external view returns (address) {
        return m_StakingAddress;
    }

    // ######## MSK #########
    function setMskContract(address _address) external onlyOwner {
        MISHKA2 = _address;
    }

    function setMskMinHold(uint256 _amount) external onlyOwner {
        m_MskMinHold = _amount.mul(10**18);
    }

    function getMskMinHold() external view returns (uint256) {
        return m_MskMinHold.div(10**18);
    }
}