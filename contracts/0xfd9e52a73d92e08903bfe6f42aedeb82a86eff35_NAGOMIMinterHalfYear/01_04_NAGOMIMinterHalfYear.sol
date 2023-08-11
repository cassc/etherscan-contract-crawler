// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface iNAGOMIHappyBirthday {
    function externalMint(address _to, uint256 _id, uint256 _amount) external;
    function sumOfTotalSupply() external view returns (uint256);
    function totalSupply(uint256 id) external view returns (uint256);
}

contract NAGOMIMinterHalfYear is Ownable {
    iNAGOMIHappyBirthday public NAGOMIHappyBirthday;

    bytes32 public freeMintMerkleRoot;
    bytes32 public allowlistMintMerkleRoot;

    uint256 public constant MAX_SUPPLY = 1299;
    uint256 public constant TOKEN_ID_ZERO_MAX_SUPPLY = 433;
    uint256 public constant TOKEN_ID_ONE_MAX_SUPPLY = 433;
    uint256 public constant TOKEN_ID_TWO_MAX_SUPPLY = 433;
    uint256 public constant MINT_COST = 0.005 ether;

    uint256[4] public withdrawShare = [40, 20, 20, 20];

    address[4] public withdrawAddress = [
        0x445513cd8ECA1E98b0C70f1Cdc52C4d986dDC987,
        0xF185B303775958C93AcFFa1231A8d14b38c049ac,
        0xCF8706F4aF69310c7372B5e9e91EF5fbc8d02C5a,
        0xe273eF71274926b7Dec32546Af84dB6e37eFADbF
    ];

    mapping(address => uint256) public freeMintCount;
    mapping(address => uint256) public allowlistMintCount;

    enum SalePhase {
        Locked,
        FreeMint,
        AllowlistMint,
        PublicMint
    }

    SalePhase public phase = SalePhase.Locked;

    event Minted(address _to, uint256 _amount);
    event PhaseChanged(SalePhase _phase);

    constructor() {}

    /**
     * モディファイア
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "called by contract");
        _;
    }

    modifier notZeroMint(uint256 _mintAmount) {
        require(_mintAmount != 0, "mintAmount is zero");
        _;
    }

    modifier enoughEth(uint256 _mintAmount) {
        require(MINT_COST * _mintAmount <= msg.value, "not enough eth");
        _;
    }

    modifier notOverMaxSupply(uint256 _mintAmount) {
        require(_mintAmount + sumOfTotalSupply() <= MAX_SUPPLY, "exceeds max supply");
        _;
    }

    /**
     * withdraw関数
     */
    /// @dev 引出し先アドレスのsetter関数
    function setWithdrawAddress(uint256 _index, address _withdrawAddress) external onlyOwner {
        require(_withdrawAddress != address(0), "withdrawAddress can't be 0");
        withdrawAddress[_index] = _withdrawAddress;
    }

    /// @dev 引出し割合のsetter関数
    function setWithdrawShare(uint256 _index, uint256 _withdrawShare) external onlyOwner {
        withdrawShare[_index] = _withdrawShare;
    }

    /// @dev 引出し用関数
    function withdraw() external payable onlyOwner {
        uint256 initialBalance = address(this).balance;
        for (uint256 index; index < withdrawAddress.length; index++) {
            require(withdrawAddress[index] != address(0), "withdrawAddress can't be 0");

            uint256 sharedAmount = (initialBalance * withdrawShare[index]) / 100;
            (bool sent,) = payable(withdrawAddress[index]).call{value: sharedAmount}("");
            require(sent, "failed to withdraw");
        }
    }

    /**
     * ミント関数
     */
    /// @dev フリーミント用のMint関数
    function freeMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        callerIsUser
        notZeroMint(_mintAmount)
        notOverMaxSupply(_mintAmount)
    {
        // セールフェイズチェック
        require(phase == SalePhase.FreeMint, "FreeMint is disabled");

        // マークルツリーチェック：ルートはfreeMintMerkleRoot
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, freeMintMerkleRoot, leaf), "Invalid Merkle Proof");

        // ミント枚数チェック：フリーミントは1枚まで
        require(freeMintCount[msg.sender] + _mintAmount <= 1, "exceeds allocation");

        randomMint(msg.sender, _mintAmount);

        // フリーミント済み数加算
        unchecked {
            freeMintCount[msg.sender] += _mintAmount;
        }
    }

    /// @dev AllowListミント用のMint関数
    function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser
        notZeroMint(_mintAmount)
        enoughEth(_mintAmount)
        notOverMaxSupply(_mintAmount)
    {
        // セールフェイズチェック
        require(phase == SalePhase.AllowlistMint, "AllowlistMint is disabled");

        // マークルツリーチェック：ルートはallowlistMintMerkleRoot
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, allowlistMintMerkleRoot, leaf), "Invalid Merkle Proof");

        // ミント枚数チェック：ALミントは2枚まで
        require(allowlistMintCount[msg.sender] + _mintAmount <= 2, "exceeds allocation");

        randomMint(msg.sender, _mintAmount);

        // ALミント数済み数加算
        unchecked {
            allowlistMintCount[msg.sender] += _mintAmount;
        }
    }

    /// @dev パブリックミント用のMint関数
    function publicMint(uint256 _mintAmount)
        external
        payable
        callerIsUser
        notZeroMint(_mintAmount)
        enoughEth(_mintAmount)
        notOverMaxSupply(_mintAmount)
    {
        // セールフェイズチェック
        require(phase == SalePhase.PublicMint, "PublicMint is disabled");

        // マークルツリーチェック：なし

        // ミント枚数チェック：購入制限なし

        randomMint(msg.sender, _mintAmount);

        // パブリックミント数済み数加算：なし
    }

    /// @dev エアドロミント関数
    function adminMint(address[] calldata _airdropAddresses, uint256[] calldata _userMintAmount) external onlyOwner {
        require(_airdropAddresses.length == _userMintAmount.length, "array length mismatch");

        uint256 _totalMintAmmount;

        for (uint256 i = 0; i < _userMintAmount.length; i++) {
            require(_userMintAmount[i] > 0, "amount 0 address exists!");

            // adminがボケた引数を入れないことが大前提
            unchecked {
                _totalMintAmmount += _userMintAmount[i];
            }

            require(_totalMintAmmount + sumOfTotalSupply() <= MAX_SUPPLY, "exceeds max supply");

            randomMint(_airdropAddresses[i], _userMintAmount[i]);
        }
    }

    /// @dev tokenId 0, 1, 2 をランダムに選んでミントするための内部関数
    /// Keisuke-san arigato-gozaimasu
    function randomMint(address _to, uint256 _amount) private {
        uint256 remaining;

        for (uint256 i = 0; i < _amount; i++) {
            unchecked {
                remaining = MAX_SUPPLY - sumOfTotalSupply();
            }
            uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % remaining;

            if (0 <= random && random < (TOKEN_ID_ZERO_MAX_SUPPLY - NAGOMIHappyBirthday.totalSupply(0))) {
                NAGOMIHappyBirthday.externalMint(_to, 0, 1);
            } else if (
                (TOKEN_ID_ZERO_MAX_SUPPLY - NAGOMIHappyBirthday.totalSupply(0)) <= random
                    && random
                        < (
                            (TOKEN_ID_ZERO_MAX_SUPPLY - NAGOMIHappyBirthday.totalSupply(0))
                                + (TOKEN_ID_ONE_MAX_SUPPLY - NAGOMIHappyBirthday.totalSupply(1))
                        )
            ) {
                NAGOMIHappyBirthday.externalMint(_to, 1, 1);
            } else {
                NAGOMIHappyBirthday.externalMint(_to, 2, 1);
            }
        }

        emit Minted(_to, _amount);
    }

    /**
     * その他の関数
     */
    /// @dev 親コントラクトのsetter
    function setNAGOMIHappyBirthday(address _contractAddress) external onlyOwner {
        NAGOMIHappyBirthday = iNAGOMIHappyBirthday(_contractAddress);
    }

    /// @dev セールフェーズのsetter
    function setPhase(SalePhase _phase) external onlyOwner {
        if (_phase != phase) {
            phase = _phase;
            emit PhaseChanged(_phase);
        }
    }

    /// @dev フリーミント用MerkleRootのsetter
    function setFreeMintMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        freeMintMerkleRoot = _merkleRoot;
    }

    /// @dev ALミント用MerkleRootのsetter
    function setAllowlistMintMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        allowlistMintMerkleRoot = _merkleRoot;
    }

    /// @dev 全tokenIdのtotalSupply和のgetter
    function sumOfTotalSupply() public view returns (uint256) {
        return NAGOMIHappyBirthday.sumOfTotalSupply();
    }
}