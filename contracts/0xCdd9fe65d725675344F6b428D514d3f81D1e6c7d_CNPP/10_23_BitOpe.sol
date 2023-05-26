// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

library BitOpe {
  uint256 private constant BITSIZE_128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 private constant BITPOS_128 = 128;
  uint256 private constant BITSIZE_64 = 0xFFFFFFFFFFFFFFFF;
  uint256 private constant BITPOS_64 = 64;
  uint256 private constant BITSIZE_32 = 0xFFFFFFFF;
  uint256 private constant BITPOS_32 = 32;
  uint256 private constant BITSIZE_16 = 0xFFFF;
  uint256 private constant BITPOS_16 = 16;
  uint256 private constant BITSIZE_8 = 0xFF;
  uint256 private constant BITPOS_8 = 8;

  uint64 private constant AUX_BITSIZE_32 = 0xFFFFFFFF;
  uint64 private constant AUX_BITPOS_32 = 32;
  uint64 private constant AUX_BITSIZE_16 = 0xFFFF;
  uint64 private constant AUX_BITPOS_16 = 16;
  uint64 private constant AUX_BITSIZE_8 = 0xFF;
  uint64 private constant AUX_BITPOS_8 = 8;

  function set128(uint256 _src, uint256 _index, uint256 _setValue) internal pure returns (uint256) {
    require(_index < 2);
    uint256 _maskdata = _src & ~(BITSIZE_128 << (_index * BITPOS_128));
    uint256 _setdata = (_setValue & BITSIZE_128) << (_index * BITPOS_128);
    return (_maskdata | _setdata);
  }

  function get128(uint256 _src, uint256 _index) internal pure returns (uint256) {
    require(_index < 2);
    uint256 _getdata = _src & BITSIZE_128;
    if(_index > 0){
       _getdata = _src >> BITPOS_128;
    }
    return _getdata;
  }

  function set64(uint256 _src, uint256 _index, uint256 _setValue) internal pure returns (uint256) {
    require(_index < 4);
    uint256  _maskdata = _src & ~(BITSIZE_64 << (BITPOS_64 * _index));
    uint256  _setdata = (_setValue & BITSIZE_64) << (BITPOS_64 * _index);
    return (_maskdata | _setdata);
  }

  function get64(uint256 _src, uint256 _index) internal pure returns (uint256) {
    require(_index < 4);
    return (_src >> (BITPOS_64 * _index)) & BITSIZE_64;
  }

  function set32(uint256 _src, uint256 _index, uint256 _setValue) internal pure returns (uint256) {
    require(_index < 8);
    uint256 _maskdata = _src & ~(BITSIZE_32 << (BITPOS_32 * _index));
    uint256 _setdata = (_setValue & BITSIZE_32) << (BITPOS_32 * _index);
    return (_maskdata | _setdata);
  }

  function get32(uint256 _src, uint256 _index) internal pure returns (uint256) {
    require(_index < 8);
    return (_src >> (BITPOS_32 * _index)) & BITSIZE_32;
  }

  function set16(uint256 _src, uint256 _index, uint256 _setValue) internal pure returns (uint256) {
    require(_index < 16);
    uint256 _maskdata = _src & ~(BITSIZE_16 << (BITPOS_16 * _index));
    uint256 _setdata = (_setValue & BITSIZE_16) << (BITPOS_16 * _index);
    return (_maskdata | _setdata);
  }

  function get16(uint256 _src, uint256 _index) internal pure returns (uint256) {
    require(_index < 16);
    return (_src >> (BITPOS_16 * _index)) & BITSIZE_16;
  }

  function set8(uint256 _src, uint256 _index, uint256 _setValue) internal pure returns (uint256) {
    require(_index < 32);
    uint256 _maskdata = _src & ~(BITSIZE_8 << (BITPOS_8 * _index));
    uint256 _setdata = (_setValue & BITSIZE_8) << (BITPOS_8 * _index);
    return (_maskdata | _setdata);
  }

  function get8(uint256 _src, uint256 _index) internal pure returns (uint256) {
    require(_index < 32);
    return (_src >> (BITPOS_8 * _index)) & BITSIZE_8;
  }

  // Aux(size uint64)
  function set32_forAux(uint64 _src,uint256 _index, uint64 _setValue) internal pure returns (uint64) {
    require(_index < 2);
    uint64 _maskdata = _src & (~AUX_BITSIZE_32);
    uint64 _setdata = _setValue & AUX_BITSIZE_32;
    if(_index > 0){
       _maskdata = _src & AUX_BITSIZE_32;
       _setdata = _setdata << AUX_BITPOS_32;
    }
    return (_maskdata | _setdata);
  }

  function get32_forAux(uint64 _src, uint256 _index) internal pure returns (uint64) {
    require(_index < 2);
    uint64 _getdata = _src & AUX_BITSIZE_32;
    if(_index > 0){
       _getdata = _src >> AUX_BITPOS_32;
    }
    return _getdata;
  }

  function set16_forAux(uint64 _src,uint256 _index, uint64 _setValue) internal pure returns (uint64) {
    require(_index < 4);
    uint64 _maskdata = _src & ~(AUX_BITSIZE_16 << (AUX_BITPOS_16 * uint64(_index)));
    uint64 _setdata = (_setValue & AUX_BITSIZE_16) << (AUX_BITPOS_16 * uint64(_index));
    return (_maskdata | _setdata);
  }

  function get16_forAux(uint64 _src, uint256 _index) internal pure returns (uint64) {
    require(_index < 4);
    return (_src >> (AUX_BITPOS_16 * _index)) & AUX_BITSIZE_16;
  }

  function set8_forAux(uint64 _src, uint256 _index, uint64 _setValue) internal pure returns (uint64) {
    require(_index < 8);
    uint64 _maskdata = _src & ~(AUX_BITSIZE_8 << (AUX_BITPOS_8 * uint64(_index)));
    uint64 _setdata = (_setValue & AUX_BITSIZE_8) << (AUX_BITPOS_8 * uint64(_index));
    return (_maskdata | _setdata);
  }

  function get8_forAux(uint64 _src, uint256 _index) internal pure returns (uint64) {
    require(_index < 8);
    return (_src >> (AUX_BITPOS_8 * _index)) & AUX_BITSIZE_8;
  }

  // uint256 index bit
  function set256bit(uint256 _src,uint256 _index, bool _setValue)  internal pure returns (uint256) {
    require(_index < 256);
    if(_setValue == false){
      _src &= ~(1 << _index);
    }else{
      _src |= (1 << _index);
    }
    return _src;
  }

  function get256bit(uint256 _src,uint256 _index) internal pure returns(bool) {
    require(_index < 256);
    bool _ret = false;
    uint256 _bit = _src & (1 << _index);
    if(_bit > 0){
      _ret = true;
    }
    return _ret;
  }

  // Options for advanced users
  function set_manual_forAux(uint64 _src,uint256 _startbit,uint256 _endbit,uint64 _setValue) internal pure returns (uint64) {
    require(_startbit < _endbit);
    require(_endbit <= 64); // 0 -64
    uint64 _manualPos_64 = 0xFFFFFFFFFFFFFFFF;
    uint64 leftmask = _manualPos_64 >> (64 - _endbit);
    uint64 rightmask = _manualPos_64 << uint64(_startbit);
    _manualPos_64 = leftmask & rightmask;
    uint64 _maskdata = _src & (~_manualPos_64);
    uint64 _setdata = _setValue << uint64(_startbit);
    return (_maskdata | _setdata);
  }

  function get_manual_forAux(uint64 _src,uint256 _startbit,uint256 _endbit) internal pure returns (uint64) {
    require(_startbit < _endbit);
    require(_endbit <= 64); // 0 -64
    uint64 _manualPos_64 = 0xFFFFFFFFFFFFFFFF;
    uint64 leftmask = _manualPos_64 >> (64 - _endbit);
    uint64 rightmask = _manualPos_64 << uint64(_startbit);
    _manualPos_64 = leftmask & rightmask;
    uint64 _getdata = (_src & _manualPos_64) >> _startbit;
    return _getdata;
  }

}