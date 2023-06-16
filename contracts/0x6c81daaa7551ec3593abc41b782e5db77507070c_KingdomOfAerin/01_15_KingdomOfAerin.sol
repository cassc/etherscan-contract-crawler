// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Enumerable.sol";

// Thank you @nftchance / @nftutc24!
contract KingdomOfAerin is ERC721Enumerable, Ownable {
    IERC20 public erc20TokenContractInstance;
    string public baseURI;

    bytes32 public merkleRoot;
    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant MAX_PER_TX_PRES = 8;
    uint256 public constant MAX_PER_TX_PS = 25;
    uint256 public constant RESERVES = 94;
    uint256 public constant priceInWei = 70000000000000000; // 0.07 eth
    uint256 public constant priceInErc20 = 2500000000000000000; // 2.5 bytes

    address public proxyRegistryAddress;
    address public erc20Wallet;

    bool public saleIsActive = false;
    bool public allowListSaleIsActive = false;

    mapping(address => bool) public projectProxy;
    mapping(address => uint256) public addressToMinted;

    constructor() ERC721("Kingdom Of Aerin", "KOA") {}

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setSale(bool _preS, bool _puS) public onlyOwner {
        allowListSaleIsActive = _preS;
        saleIsActive = _puS;
    }

    function setErc20Wallet(address wallet) public onlyOwner {
        erc20Wallet = wallet;
    }

    function setErc20TokenAddress(address _erc20TokenAddress) public onlyOwner {
        erc20TokenContractInstance = IERC20(_erc20TokenAddress);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function getGiveaways() external onlyOwner {
        require(_owners.length == 0, "Reserves already taken.");
        for (uint256 i; i < RESERVES; i++) {
            _mint(_msgSender(), i);
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function allowlistMint(uint256 count, bytes32[] calldata proof)
        public
        payable
    {
        uint256 totalSupply = _owners.length;
        require(!saleIsActive, "Sale already in progress");
        require(allowListSaleIsActive, "Allow List Sale must be active");
        require(count < (MAX_PER_TX_PRES + 1), "Rq qty > maximum pre");
        require(totalSupply + count < (MAX_SUPPLY + 1), "Exceedes max supply.");
        require(
            count * priceInWei == msg.value,
            "Incorrect amount of funds provided."
        );

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(proof, merkleRoot, leaf),
            "Not in Allow List"
        );

        addressToMinted[_msgSender()] += count;
        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function publicMint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;
        require(saleIsActive, "Sale not on");
        require(totalSupply + count < (MAX_SUPPLY + 1), "Exceedes max supply.");
        require(count < (MAX_PER_TX_PS + 1), "Exceeds max per transaction.");
        require(
            count * priceInWei == msg.value,
            "Incorrect amount of funds provided."
        );

        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function allowlistMintWithErc20(uint256 count, bytes32[] calldata proof)
        public
        payable
    {
        uint256 totalSupply = _owners.length;
        require(!saleIsActive, "Sale already in progress");
        require(allowListSaleIsActive, "Allow List Sale must be active");
        require(count < (MAX_PER_TX_PRES + 1), "Rq qty > maximum pre");
        require(totalSupply + count < (MAX_SUPPLY + 1), "Exceedes max supply.");
        require(
            count * priceInErc20 <
                erc20TokenContractInstance.allowance(msg.sender, address(this)),
            "Insufficient allowance"
        );
        require(
            count * priceInErc20 <
                erc20TokenContractInstance.balanceOf(msg.sender),
            "Not enough Bytes to mint!"
        );

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(proof, merkleRoot, leaf),
            "Not in Allow List"
        );

        erc20TokenContractInstance.transferFrom(
            msg.sender,
            erc20Wallet,
            count * priceInErc20
        );

        addressToMinted[_msgSender()] += count;
        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function publicMintWithErc20(uint256 count) public payable {
        uint256 totalSupply = _owners.length;
        require(saleIsActive, "Sale not on");
        require(totalSupply + count < (MAX_SUPPLY + 1), "Exceedes max supply.");
        require(count < (MAX_PER_TX_PS + 1), "Exceeds max per transaction.");
        require(
            count * priceInErc20 <
                erc20TokenContractInstance.allowance(msg.sender, address(this)),
            "Insufficient allowance"
        );
        require(
            count * priceInErc20 <
                erc20TokenContractInstance.balanceOf(msg.sender),
            "Not enough Bytes to mint!"
        );

        erc20TokenContractInstance.transferFrom(
            msg.sender,
            erc20Wallet,
            count * priceInErc20
        );

        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved to burn."
        );
        _burn(tokenId);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    // https://twitter.com/0xInuarashi/status/1481092010698473474
    function walletOfOwner(address _address)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(_address);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == _address) {
                    _tokens[_index] = i;
                    _index++;
                }
            } else if (!_exists && _tokens[_balance - 1] == 0) {
                _loopThrough++;
            }
        }
        return _tokens;
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }

        return true;
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );
        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            projectProxy[operator]
        ) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}