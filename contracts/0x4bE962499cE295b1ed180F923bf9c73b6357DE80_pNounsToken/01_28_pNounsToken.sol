// SPDX-License-Identifier: MIT

/*
 * Created by Eiba (@eiba8884)
 */
/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./pNounsContractFilter.sol";

contract pNounsToken is pNounsContractFilter {
    using Strings for uint256;

    enum SalePhase {
        Locked,
        PreSale,
        PublicSale
    }
    SalePhase public phase = SalePhase.Locked; // セールフェーズ
    uint256 public purchaseUnit = 5; // 購入単位

    bytes32 public merkleRoot; // プレセールのマークルルート
    address public constant treasuryAddress = 0x8AE80e0B44205904bE18869240c2eC62D2342785; // トレジャリーウォレット
    uint256 public maxMintPerAddress = 100; // 1人当たりの最大ミント数
    uint256 constant mintForTreasuryAddress = 100; // トレジャリーへの初回配布数

    mapping(address => uint256) public mintCount; // アドレスごとのミント数

    constructor(
        IAssetProvider _assetProvider,
        address[] memory _administrators
    )
        pNounsContractFilter(
            _assetProvider,
            "pNouns NFT",
            "pNouns",
            _administrators
        )
    {
        description = "This is the first NFT of pNouns project (https://pnouns.wtf/).";
        mintPrice = 0.05 ether;
        mintLimit = 2100;

        _safeMint(treasuryAddress, mintForTreasuryAddress);
        nextTokenId += mintForTreasuryAddress;

        mintCount[treasuryAddress] += mintForTreasuryAddress;
    }

    function adminMint(address[] memory _to, uint256[] memory _num)
        public
        onlyAdminOrOwner
    {
        uint256 mintTotal = 0;
        uint256 limitAdminMint = 100; // 引数間違いに備えてこのトランザクション内での最大ミント数を設定しておく

        // 引数配列の整合性チェック
        require(_to.length == _num.length, "args error");

        for (uint256 i = 0; i < _num.length; i++) {
            mintTotal += _num[i];
            require(_num[i] > 0, "mintAmount is zero");
        }

        // ミント数合計が最大ミント数を超えていないか
        require(mintTotal <= limitAdminMint, "exceed limitAdminMint");
        require(totalSupply() + mintTotal <= mintLimit, "exceed mintLimit");

        // ミント処理
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], _num[i]);
            mintCount[_to[i]] += _num[i];
        }
        nextTokenId += mintTotal;
    }

    function mintPNouns(
        uint256 _mintAmount, // ミント数
        bytes32[] calldata _merkleProof // マークルツリー
    ) external payable {
        // オーナーチェック
        if (!hasAdminOrOwner()) {
            // originチェック
            require(tx.origin == msg.sender, "cannot mint from non-origin");

            // セールフェイズチェック
            if (phase == SalePhase.Locked) {
                revert("Sale locked");
            } else if (phase == SalePhase.PreSale) {
                // マークルツリーが正しいこと
                bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
                require(
                    MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf),
                    "Invalid Merkle Proof"
                );
            } else if (phase == SalePhase.PublicSale) {
                // チェック不要
            }

            // ミント数が購入単位と一致していること,ミント数が設定されていること
            require(
                _mintAmount % purchaseUnit == 0 && _mintAmount > 0,
                "Invalid purchaseUnit"
            );

            // アドレスごとのミント数上限チェック
            require(
                mintCount[msg.sender] + _mintAmount <= maxMintPerAddress,
                "exceeds number of per address"
            );

            // ミント数に応じた ETHが送金されていること
            uint256 cost = mintPrice * _mintAmount;
            require(cost <= msg.value, "insufficient funds");
        } else {
            require(msg.value == 0, "owners mint price is free");
        }

        // 最大供給数に達していないこと
        require(totalSupply() + _mintAmount <= mintLimit, "Sold out");

        // ミント
        // for (uint256 i; i < _mintAmount; i++) {
        //     _safeMint(msg.sender, nextTokenId + i);
        // }
        _safeMint(msg.sender, _mintAmount);
        nextTokenId += _mintAmount;

        // ミント数カウントアップ
        mintCount[msg.sender] += _mintAmount;
    }

    function withdraw() external payable onlyAdminOrOwner {
        require(
            treasuryAddress != address(0),
            "treasuryAddress shouldn't be 0"
        );
        (bool sent, ) = payable(treasuryAddress).call{
            value: address(this).balance
        }("");
        require(sent, "failed to move fund to treasuryAddress contract");
    }

    /* treasuryAddress は non-upgradable */
    // function setTreasuryAddress(address _treasury) external onlyAdminOrOwner {
    //     treasuryAddress = _treasury;
    // }

    function setPhase(SalePhase _phase, uint256 _purchaseUnit)
        external
        onlyAdminOrOwner
    {
        phase = _phase;
        purchaseUnit = _purchaseUnit;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyAdminOrOwner {
        merkleRoot = _merkleRoot;
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress)
        external
        onlyAdminOrOwner
    {
        maxMintPerAddress = _maxMintPerAddress;
    }

    function mint() public payable override returns (uint256) {
        revert("this function is not used");
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenName(uint256 _tokenId)
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked("pNouns #", _tokenId.toString()));
    }

    // 10% royalties for treasuryAddressß
    function _processRoyalty(uint256 _salesPrice, uint256)
        internal
        virtual
        override
        returns (uint256 royalty)
    {
        royalty = (_salesPrice * 100) / 1000; // 10.0%
        address payable payableTo = payable(treasuryAddress);
        payableTo.transfer(royalty);
    }
}