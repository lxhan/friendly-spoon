---
name: Bug report
description: Report friendly-spoon not working as expected
title: "Bug: "
labels: [bug]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for reporting. Please include enough detail to reproduce the problem.
  - type: input
    id: macos
    attributes:
      label: macOS version
      placeholder: "e.g. macOS 15.5"
    validations:
      required: true
  - type: input
    id: keyboard
    attributes:
      label: Keyboard model and firmware
      placeholder: "e.g. split keyboard model, firmware/version"
    validations:
      required: true
  - type: dropdown
    id: bluetooth-battery
    attributes:
      label: Does macOS Bluetooth settings show battery level?
      options:
        - "Yes"
        - "No"
        - "Not sure"
    validations:
      required: true
  - type: textarea
    id: problem
    attributes:
      label: What happened?
      description: Include friendly-spoon status text and what you expected.
    validations:
      required: true
  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
      value: |
        1.
        2.
        3.
    validations:
      required: false
  - type: textarea
    id: screenshots
    attributes:
      label: Screenshots or logs
      description: Drag screenshots here if useful.
    validations:
      required: false
