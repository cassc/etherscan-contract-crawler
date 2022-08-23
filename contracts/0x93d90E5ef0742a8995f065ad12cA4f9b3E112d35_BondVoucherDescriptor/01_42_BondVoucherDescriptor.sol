// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@solv/v2-solidity-utils/contracts/access/AdminControl.sol";
import "@solv/v2-solidity-utils/contracts/misc/StringConvertor.sol";
import "@solv/v2-solidity-utils/contracts/misc/BokkyPooBahsDateTimeLibrary.sol";
import "@solv/v2-solidity-utils/contracts/openzeppelin/token/ERC20/ERC20Upgradeable.sol";
import "./interface/IVNFTDescriptor.sol";
import "./interface/IVoucherSVG.sol";
import "./BondVoucher.sol";
import "./BondPool.sol";
import "base64-sol/base64.sol";

contract BondVoucherDescriptor is IVNFTDescriptor, AdminControl {

    event SetVoucherSVG(
        address indexed voucher,
        address oldVoucherSVG,
        address newVoucherSVG
    );

    event SetBondWarrant(
        address indexed voucher,
        uint256 indexed slot,
        string bondWarrant
    );

    using StringConvertor for address;
    using StringConvertor for uint256;
    using StringConvertor for bytes;

    // BondVoucher address => VoucherSVG address
    // Mapping value of 0x0 is defined as default VoucherSVG
    mapping(address => address) public voucherSVGs;

    // BondVoucher address => slot => bond warrant
    mapping(address => mapping(uint256 => string)) public bondWarrants;


    function initialize(address defaultVoucherSVG_) external initializer {
        AdminControl.__AdminControl_init(_msgSender());
        setVoucherSVG(address(0), defaultVoucherSVG_);
    }

    function setVoucherSVG(address voucher_, address voucherSVG_) public onlyAdmin {
        emit SetVoucherSVG(voucher_, voucherSVGs[voucher_], voucherSVG_);
        voucherSVGs[voucher_] = voucherSVG_;
    }

    function setBondWarrant(address voucher_, uint256 slot_, string calldata bondWarrant) external onlyAdmin {
        emit SetBondWarrant(voucher_, slot_, bondWarrant);
        bondWarrants[voucher_][slot_] = bondWarrant;
    }

    function contractURI() external view override returns (string memory) { 
        BondVoucher voucher = BondVoucher(_msgSender());
        return string(
            abi.encodePacked(
                'data:application/json;{"name":"', voucher.name(),
                '","description":"', _contractDescription(voucher),
                '","unitDecimals":"', uint256(voucher.unitDecimals()).toString(),
                '","properties":{}}'
            )
        );
    }

    function slotURI(uint256 slot_) external view override returns (string memory) {
        BondVoucher voucher = BondVoucher(_msgSender());
        BondPool pool = voucher.bondPool();
        BondPool.SlotDetail memory slotDetail = pool.getSlotDetail(slot_);

        return string(
            abi.encodePacked(
                'data:application/json;{"unitsInSlot":"', voucher.unitsInSlot(slot_).toString(),
                '","tokensInSlot":"', voucher.tokensInSlot(slot_).toString(),
                '","properties":', _properties(pool, slot_, slotDetail),
                '}'
            )
        );
    }

    function tokenURI(uint256 tokenId_)
        external
        view
        virtual
        override
        returns (string memory)
    {
        BondVoucher voucher = BondVoucher(_msgSender());
        BondPool pool = voucher.bondPool();

        uint256 slot = voucher.slotOf(tokenId_);
        BondPool.SlotDetail memory slotDetail = pool.getSlotDetail(slot);
        
        bytes memory name = abi.encodePacked(voucher.name(), ' #', tokenId_.toString());

        address voucherSVG = voucherSVGs[_msgSender()];
        if (voucherSVG == address(0)) {
            voucherSVG = voucherSVGs[address(0)];
        }
        string memory image = IVoucherSVG(voucherSVG).generateSVG(_msgSender(), tokenId_);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"', name, 
                            '","description":"', _tokenDescription(voucher, tokenId_, slotDetail),
                            '","image":"data:image/svg+xml;base64,', Base64.encode(bytes(image)),
                            '","balance":"', voucher.unitsInToken(tokenId_).toString(),
                            '","slot":"', slot.toString(),
                            '","properties":', _properties(pool, slot, slotDetail),
                            '}'
                        )
                    )
                )
            );
    }

    function _contractDescription(BondVoucher voucher) 
        private 
        view
        returns (bytes memory)
    {
        string memory underlyingSymbol = ERC20Upgradeable(voucher.underlying()).symbol();

        return abi.encodePacked(
            underlyingSymbol, 'Bond Voucher.', '\\n\\n',
            _descVoucher(), '\\n\\n', 
            _descAlert(), '\\n\\n', 
            _descProtocol()
        );
    }

    function _tokenDescription(
        BondVoucher voucher, 
        uint256 tokenId, 
        BondPool.SlotDetail memory slotDetail
    )
        private
        view
        returns (bytes memory)
    {
        string memory underlyingSymbol = ERC20Upgradeable(voucher.underlying()).symbol();

        return abi.encodePacked(
            underlyingSymbol, ' Bond Voucher #', tokenId.toString(), '. \\n\\n',
            _descVoucher(), '\\n\\n', 
            abi.encodePacked(
                '- Voucher Address: ', address(voucher).addressToString(), '\\n',
                '- Pool Address: ', address(voucher.bondPool()).addressToString(), '\\n',
                "- Underlying asset's address: ", voucher.underlying().addressToString(), '\\n',
                "- Borrowed asset's address: ", slotDetail.fundCurrency.addressToString()
            ),
            '\\n\\n',
            _descAlert()
        );
    }

    function _descAlert() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    unicode'⚠️ ', 
                    'Before you buy or make an offer: ',
                    '\\n\\n',
                    'Please be aware that the price displayed on this platform may not reflect the latest price change. For reliable price data, collateral report and repayment details, please visit the Solv dApp at app.solv.finance.'
                )
            );
    }

    function _descVoucher() private pure returns (string memory) {
        return 
            string(
                abi.encodePacked(
                    'Bond Voucher is an ERC3525-powered zero-coupon bond that provides convertibility into the underlying tokens as a bonus. A Bond Voucher is minted to allow the issuer to borrow an amount of asset for a period of time (term to maturity) and enable the holder to receive the principal and accrued interest as fixed income.',
                    '\\n\\n', 
                    'At maturity, if the underlying token trades below a predefined strike price (or \\"conversion price\\"), ',
                    "the holder receives the Voucher's denomination as payment. If the token trades above the conversion price, the holder receives the upside as a bonus.",
                    '\\n\\n',
                    'To learn more about the Bond Voucher, read this doc: https://docs.solv.finance/solv-documentation/featured-products/bond-voucher'
                )
            );
    }

    function _descProtocol() private pure returns (string memory) {
        return 'Solv Protocol is the decentralized platform for creating, managing and trading Financial NFTs.';
    }

    function _properties(
        BondPool pool,
        uint256 slot,
        BondPool.SlotDetail memory slotDetail
    ) 
        private
        view
        returns (bytes memory data) 
    {
        string memory bondWarrant = bondWarrants[_msgSender()][slot];
        if (bytes(bondWarrant).length == 0) {
            bondWarrant = bondWarrants[_msgSender()][0];
        }

        return 
            abi.encodePacked(
                abi.encodePacked(
                    '{"underlyingToken":"', pool.underlyingToken().addressToString(),
                    '","fundCurrency":"', slotDetail.fundCurrency.addressToString(), 
                    '","issuer":"', slotDetail.issuer.addressToString(),
                    '","totalValue":"', _formatValue(slotDetail.totalValue, pool.valueDecimals()),
                    '","bondWarrant":"', bondWarrant
                ),
                abi.encodePacked(
                    '","conversionPrice":"', _formatValue(slotDetail.highestPrice, pool.priceDecimals()),
                    '","settlePrice":"', _formatValue(slotDetail.settlePrice, pool.priceDecimals()),
                    '","effectiveTime":"', uint256(slotDetail.effectiveTime).datetimeToString(),
                    '","maturity":"', uint256(slotDetail.maturity).datetimeToString(),
                    '"}'
                )
            );
    }

    function _formatValue(uint256 value, uint8 decimals) private pure returns (bytes memory) {
        return value.uint2decimal(decimals).trim(decimals - 2).addThousandsSeparator();
    }

}