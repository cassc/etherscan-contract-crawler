// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ProbabilityMap {
    function _mapCollectionId(uint256 _serialNumber)
        internal
        pure
        returns (uint256)
    {
        if (_serialNumber > 645) {
            if (_serialNumber > 1125) {
                if (_serialNumber > 1424) {
                    if (_serialNumber > 1525) {
                        if (_serialNumber > 1575) {
                            if (_serialNumber > 1625) {
                                return 102;
                            } else {
                                return 101;
                            }
                        } else {
                            return 100;
                        }
                    } else {
                        if (_serialNumber > 1475) {
                            return 99;
                        } else {
                            return 98;
                        }
                    }
                } else {
                    if (_serialNumber > 1275) {
                        if (_serialNumber > 1325) {
                            if (_serialNumber > 1375) {
                                return 97;
                            } else {
                                return 96;
                            }
                        } else {
                            return 95;
                        }
                    } else {
                        if (_serialNumber > 1175) {
                            if (_serialNumber > 1225) {
                                return 94;
                            } else {
                                return 93;
                            }
                        } else {
                            return 92;
                        }
                    }
                }
            } else {
                if (_serialNumber > 855) {
                    if (_serialNumber > 975) {
                        if (_serialNumber > 1025) {
                            if (_serialNumber > 1075) {
                                return 91;
                            } else {
                                return 90;
                            }
                        } else {
                            return 89;
                        }
                    } else {
                        if (_serialNumber > 890) {
                            if (_serialNumber > 925) {
                                return 88;
                            } else {
                                return 87;
                            }
                        } else {
                            return 86;
                        }
                    }
                } else {
                    if (_serialNumber > 750) {
                        if (_serialNumber > 785) {
                            if (_serialNumber > 820) {
                                return 85;
                            } else {
                                return 84;
                            }
                        } else {
                            return 83;
                        }
                    } else {
                        if (_serialNumber > 680) {
                            if (_serialNumber > 715) {
                                return 82;
                            } else {
                                return 81;
                            }
                        } else {
                            return 80;
                        }
                    }
                }
            }
        } else {
            if (_serialNumber > 275) {
                if (_serialNumber > 435) {
                    if (_serialNumber > 540) {
                        if (_serialNumber > 575) {
                            if (_serialNumber > 610) {
                                return 79;
                            } else {
                                return 78;
                            }
                        } else {
                            return 77;
                        }
                    } else {
                        if (_serialNumber > 470) {
                            if (_serialNumber > 505) {
                                return 76;
                            } else {
                                return 75;
                            }
                        } else {
                            return 74;
                        }
                    }
                } else {
                    if (_serialNumber > 350) {
                        if (_serialNumber > 375) {
                            if (_serialNumber > 400) {
                                return 73;
                            } else {
                                return 72;
                            }
                        } else {
                            return 71;
                        }
                    } else {
                        if (_serialNumber > 300) {
                            if (_serialNumber > 325) {
                                return 70;
                            } else {
                                return 69;
                            }
                        } else {
                            return 68;
                        }
                    }
                }
            } else {
                if (_serialNumber > 130) {
                    if (_serialNumber > 200) {
                        if (_serialNumber > 225) {
                            if (_serialNumber > 250) {
                                return 67;
                            } else {
                                return 66;
                            }
                        } else {
                            return 65;
                        }
                    } else {
                        if (_serialNumber > 150) {
                            if (_serialNumber > 175) {
                                return 64;
                            } else {
                                return 63;
                            }
                        } else {
                            return 62;
                        }
                    }
                } else {
                    if (_serialNumber > 70) {
                        if (_serialNumber > 90) {
                            if (_serialNumber > 110) {
                                return 61;
                            } else {
                                return 60;
                            }
                        } else {
                            return 59;
                        }
                    } else {
                        if (_serialNumber > 45) {
                            if (_serialNumber > 50) {
                                return 58;
                            } else {
                                return 57;
                            }
                        } else {
                            return _serialNumber + 11;
                        }
                    }
                }
            }
        }
    }
}