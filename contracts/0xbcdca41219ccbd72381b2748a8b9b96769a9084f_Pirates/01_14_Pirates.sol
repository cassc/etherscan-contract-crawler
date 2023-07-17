// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Pirates is ERC721A, Ownable {
    string public baseTokenURI;
    string public provenanceHash = "";
    uint256 public _seed = 0;

    bool public publicMintPaused = true;

    IERC20 private eggsContract;
    mapping(address => uint256) private publicMintWalletCount;
    mapping(address => uint256) private allowListWalletCount;

    uint256 private _price = 0.07 ether;   // 70000000000000000
    uint256 private _priceEggs = 56 ether; // 56000000000000000000

    uint256 public numMintedWithEggs = 0;
    uint256 public numMintedWithEth = 0;

    uint256 private _maxSupply = 8888;
    uint256 private _maxEthSupply = 5500;
    uint256 private _maxEggSupply = 3388;

    address private _verifier = 0xcFe5cb192f8E2B10dCc3a3618b9b936Eac26B4C4;
    address public stakingContract = 0x244938DAd845F5ffA30618b20c526359e18D2E34;

    constructor(address eggsAddress, string memory baseURI) ERC721A("Pirates", "PIRATES") {
        eggsContract = IERC20(eggsAddress);
        setBaseURI(baseURI);
    }

    function _recoverWallet(
        address _wallet,
        uint256 _num,
        bytes memory _signature
    ) internal pure returns (address) {
        return
        ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(_wallet, _num))
            ),
            _signature
        );
    }

    function _maybeSetSeed(uint256 totalSupply) internal {
        if (_seed == 0 && totalSupply == (_maxEthSupply + _maxEggSupply)) {
            _seed = uint256(
                keccak256(abi.encodePacked(block.difficulty, block.timestamp))
            );
        }
    }

    function mint(uint256 _num) external payable {
        uint256 totalSupply = totalSupply();

        require(!publicMintPaused, "Minting paused");
        require(totalSupply + _num <= (_maxEthSupply + _maxEggSupply), "Exceeds maximum supply");
        require(numMintedWithEth + _num <= _maxEthSupply, "Exceeds maximum supply mintable with ether");
        require(publicMintWalletCount[_msgSender()] + _num < 6, "Max mint per wallet is 5");
        require(msg.value >= _price * _num, "Ether sent is not correct");

        numMintedWithEth += _num;
        publicMintWalletCount[_msgSender()] += _num;

        _mint(_msgSender(), _num, '', false);
        _maybeSetSeed(totalSupply + _num);
    }

    function allowListMint(uint256 _num, bytes calldata _signature, uint256 _max, bytes calldata _maxSignature) external payable {
        uint256 totalSupply = totalSupply();

        require(
            tx.origin == msg.sender,
            "Purchase cannot be called from another contract"
        );
        require(totalSupply + _num <= (_maxEthSupply + _maxEggSupply), "Exceeds maximum supply");
        require(numMintedWithEth + _num <= _maxEthSupply, "Exceeds maximum supply mintable with ether");
        require(allowListWalletCount[_msgSender()] + _num <= _max, "Exceeds maximum allow list supply for this wallet");
        require(msg.value >= _price * _num, "Ether sent is not correct");

        address signer = _recoverWallet(_msgSender(), _num, _signature);
        require(signer == _verifier, "Unverified transaction");
        signer = _recoverWallet(_msgSender(), _max, _maxSignature);
        require(signer == _verifier, "Unverified max allowlist signature");

        numMintedWithEth += _num;
        allowListWalletCount[_msgSender()] += _num;

        _mint(_msgSender(), _num, '', false);
        _maybeSetSeed(totalSupply + _num);
    }

    function mintWithEggs(uint256 _num) external payable {
        uint256 totalSupply = totalSupply();

        require(!publicMintPaused, "Minting paused");
        require(numMintedWithEggs + _num <= _maxEggSupply, "Exceeds maximum supply mintable with eggs");

        uint256 amountToPay = _num * _priceEggs;
        require(eggsContract.allowance(msg.sender, address(this)) >= amountToPay, "Insufficient Allowance");
        require(eggsContract.transferFrom(msg.sender, address(this), amountToPay), "Transfer Failed");

        numMintedWithEggs += _num;

        _mint(_msgSender(), _num, '', false);
        _maybeSetSeed(totalSupply + _num);
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        // Allow the staking contract to transfer without require user to approve first (to save gas)
        if (stakingContract == _operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory _data
    ) public {
        for (uint256 i; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], _data);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function walletOfOwner(address owner)
    external
    view
    returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokensId;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setVerifier(address _newVerifier) external onlyOwner {
        _verifier = _newVerifier;
    }

    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
    }

    function setSupplies(uint256 _newEthAmount, uint256 _newEggAmount) external onlyOwner {
        require(_newEthAmount + _newEggAmount == _maxSupply, "Amounts must add up to max supply");
        _maxEthSupply = _newEthAmount;
        _maxEggSupply = _newEggAmount;
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function publicMintPause(bool _state) public onlyOwner {
        publicMintPaused = _state;
    }

    function emergencySetSeed() external onlyOwner {
        require(_seed == 0, "Seed is already set");
        _seed = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );
    }

    function withdraw() external onlyOwner {
        require(
            payable(owner()).send(address(this).balance),
            "Withdraw unsuccessful"
        );
    }

    function withdrawEggs(uint256 _amount) external onlyOwner {
        require(eggsContract.approve(address(this), _amount), "Approval unsuccessful");
        require(eggsContract.transferFrom(address(this), address(eggsContract), _amount), "WithdrawEggs unsuccessful");
    }
}